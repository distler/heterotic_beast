# Replaces the vendored rspec_on_rails_on_crack plugin with a small, RSpec-3
# native implementation of the controller/model spec DSL the legacy specs
# rely on: act!, acting, it_assigns, it_renders, it_redirects_to, plus
# helpers like asserts_status / asserts_content_type and the validation
# macros it_validates_presence_of / it_validates_uniqueness_of.

module LegacyControllerDSL
  module ClassMethods
    # act! { get :index, ... }     — store the block to run as the action
    # act!                          — (instance) run the stored block
    def act!(&block)
      if block
        @acting_block = block
      else
        # Called inside an example's body: forward to the instance method.
        super() if defined?(super)
      end
    end

    def acting_block
      @acting_block || (superclass.respond_to?(:acting_block) ? superclass.acting_block : nil)
    end

    VARIABLE_TYPES = { headers: :to_s, flash: nil, session: nil }.freeze

    def it_assigns(*names)
      names.each do |name|
        case name
        when Symbol
          it_assigns_example_values(name, name)
        when Hash
          name.each do |key, value|
            if VARIABLE_TYPES.key?(key)
              it_assigns_collection(key, value)
            else
              it_assigns_example_values(key, value)
            end
          end
        end
      end
    end

    def it_assigns_example_values(name, value)
      it "assigns @#{name}" do
        act!
        case value
        when :not_nil
          assigns[name].should_not be_nil
        when :undefined
          controller.send(:instance_variables).should_not include(:"@#{name}")
        when Symbol
          if (instance_variable = instance_variable_get("@#{value}")).nil?
            assigns[name].should_not be_nil
          else
            assigns[name].should == instance_variable
          end
        when Proc
          # `it_assigns :parent => lambda { @topic }` — evaluate in the
          # example's context so `@ivars` resolve to the example's setup.
          assigns[name].should == instance_exec(&value)
        else
          assigns[name].should == value
        end
      end
    end

    def it_assigns_collection(collection_type, values)
      cast = VARIABLE_TYPES[collection_type]
      values.each do |key, value|
        keyed = cast ? key.send(cast) : key
        it "assigns #{collection_type}[#{keyed.inspect}]" do
          acting do |resp|
            collection = case collection_type
                         when :session then request.session
                         when :flash   then flash
                         when :headers then resp.headers
                         else               resp.send(collection_type)
                         end
            case value
            when nil          then collection[keyed].should be_nil
            when :not_nil     then collection[keyed].should_not be_nil
            when :undefined   then collection.should_not include(keyed)
            when Proc         then collection[keyed].should == instance_exec(&value)
            else                   collection[keyed].should == value
            end
          end
        end
      end
    end

    def it_renders(render_method, *args, &block)
      send("it_renders_#{render_method}", *args, &block)
    end

    def it_renders_blank(options = {})
      it 'renders a blank response' do
        acting do |response|
          asserts_status options[:status]
          response.body.strip.should be_blank
        end
      end
    end

    def it_renders_template(template_name, options = {})
      it "renders #{template_name}" do
        acting do |response|
          asserts_status options[:status]
          asserts_content_type options[:format]
          response.should render_template(template_name.to_s)
        end
      end
    end

    def it_renders_xml(record = nil, options = {}, &block)
      it_renders_xml_or_json(:xml, record, options, &block)
    end

    def it_renders_json(record = nil, options = {}, &block)
      it_renders_xml_or_json(:json, record, options, &block)
    end

    def it_renders_xml_or_json(format, record = nil, options = {}, &block)
      if record.is_a?(Hash)
        options = record
        record  = nil
      end

      it "renders #{format}" do
        if record
          pieces = record.to_s.split('.')
          record = instance_variable_get("@#{pieces.shift}")
          record = record.send(pieces.shift) until pieces.empty?
          block ||= -> { record.send("to_#{format}") }
        end

        acting do |response|
          asserts_status options[:status]
          asserts_content_type(options[:format] || format)
          response.body.should include(instance_exec(&block).to_s) if block
        end
      end
    end

    def it_redirects_to(hint = nil, &route)
      hint ||= 'computed url'
      it "redirects to #{hint}" do
        acting.should redirect_to(instance_exec(&route))
      end
    end
  end

  # Rails 5.1 fully removed the legacy positional-args form for the
  # controller test verb helpers (`get :show, id: 1`) — it now requires
  # the keyword form (`get :show, params: { id: 1 }`). The hundreds of
  # `act! { get :index, ... }` blocks in the legacy specs use the old
  # form. Rather than rewrite every block, intercept the verb helpers
  # here and translate positional → keyword on the fly.
  module LegacyHTTPVerbCompat
    KW_OPTIONS = [:params, :session, :flash, :body, :xhr, :format, :as].freeze

    %w[get post put patch delete head].each do |verb|
      # No **kwargs in the signature — Ruby 2.6's auto-conversion of a
      # trailing symbol-keyed hash into **kwargs would swallow legacy
      # positional-hash calls (`get :foo, :bar => 1`) and pass them
      # through as kwargs, where they'd hit `unknown keyword`.
      define_method(verb) do |action, *args|
        # Legacy positional-hash form: a single positional Hash, split
        # unconditionally — any key that's a Rails-5+ keyword option
        # (`:params`, `:format`, `:xhr`, etc.) goes into the matching
        # kwarg slot, the rest go into `params:`. Even if every key
        # happens to be a kwarg option, we still need to convert; Rails
        # 7.1 has no positional Hash form at all.
        if args.length == 1 && args.first.is_a?(Hash)
          opts = args.shift.dup
          kwargs = {}
          KW_OPTIONS.each do |k|
            kwargs[k] = opts.delete(k) if opts.key?(k)
          end
          kwargs[:params] = opts unless opts.empty?
          super(action, **kwargs)
        else
          super(action, *args)
        end
      end
    end
  end

  module InstanceMethods
    def acting(&block)
      act!
      block.call(response) if block
      response
    end

    def act!
      blk = self.class.acting_block
      raise 'no act! block defined for this example group' unless blk
      instance_exec(&blk)
    end

    def do_stubbed_action(method, action, params = {})
      controller.stub(action)
      send(method, action, params)
    end

    def asserts_content_type(type = :html)
      mime = Mime::Type.lookup_by_extension((type || :html).to_s)
      # Rails 6+ `response.content_type` includes the charset suffix, e.g.
      # "text/html; charset=utf-8". Compare on the media-type only.
      response.media_type.should == mime.to_s
    end

    def asserts_status(status)
      case status
      when String, Integer
        response.code.should == status.to_s
      when Symbol
        # `Rack::Utils::SYMBOL_TO_STATUS_CODE` was renamed in modern Rack —
        # `Rack::Utils.status_code(symbol)` is the supported lookup.
        code_value = Rack::Utils.status_code(status)
        response.code.should == code_value.to_s
      else
        # `Response#success?` was removed in Rails 6.0; `successful?` remains.
        response.should be_successful
      end
    end

    # `violated 'msg'` was an old assertion macro. With RSpec 3 we just fail.
    def violated(message)
      raise RSpec::Expectations::ExpectationNotMetError, message
    end
  end
end

module LegacyModelDSL
  module ClassMethods
    def it_validates_presence_of(model, *attributes)
      it "validates presence of: #{attributes.to_sentence}" do
        errors = attributes.map do |attr|
          create_record_from_attributes
          next "Invalid with default attributes: #{@record.errors.full_messages.to_sentence}" unless @record.valid?
          @record.send("#{attr}=", nil)
          @record.valid? ? "Valid with @record.#{attr} == nil" : nil
        end.compact
        violated "Errors: #{errors.to_sentence}" unless errors.empty?
      end
    end

    def it_validates_uniqueness_of(model, *attributes)
      it "validates uniqueness of: #{attributes.to_sentence}" do
        errors = attributes.map do |attr|
          create_record_from_attributes
          @record.save
          next "Invalid with default attributes: #{@record.errors.full_messages.to_sentence}" if @record.new_record?
          create_record_from_attributes
          (@record.valid? || @record.errors[attr].nil?) ? "Valid with duplicate @record.#{attr}" : nil
        end.compact
        violated "Errors: #{errors.to_sentence}" unless errors.empty?
      end
    end
  end

  module InstanceMethods
    def create_record_from_attributes
      @record = @record.class.new
      @attributes.each { |key, value| @record.send("#{key}=", value) }
    end

    def violated(message)
      raise RSpec::Expectations::ExpectationNotMetError, message
    end
  end
end

RSpec.configure do |config|
  config.extend  LegacyControllerDSL::ClassMethods,    type: :controller
  config.include LegacyControllerDSL::InstanceMethods, type: :controller
  config.prepend LegacyControllerDSL::LegacyHTTPVerbCompat, type: :controller
  config.extend  LegacyModelDSL::ClassMethods,         type: :model
  config.include LegacyModelDSL::InstanceMethods,      type: :model
end
