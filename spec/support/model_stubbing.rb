# Replaces the vendored model_stubbing plugin. The legacy specs sprinkle
# `define_models` (with optional name and block) at the top of every
# describe — under the original plugin this registered fixture data
# (creating records before each example). We now create records lazily
# through factories (see legacy_fixtures.rb).
#
# `define_models`:
#   * Pre-seeds the default fixture chain (sites(:default),
#     users(:default)) in a `before(:each)` hook so the controller's
#     `current_site` lookup works.
#   * If given a block, interprets `model Klass do; stub :name, attrs;
#     end` declarations and pre-creates matching records keyed under
#     the legacy fixture name. Inside the block, `current_time` and
#     `all_stubs(:other_name)` are available (the latter creates the
#     referenced fixture lazily so cross-references work regardless of
#     declaration order).

module LegacyDefineModels
  # Map `define_models :foo, :bar` arguments to fixture sets that should
  # be pre-created beyond the default Site+User chain.
  EXTRA_FIXTURE_SETS = {
    forums:         [[:forum,   :default]],
    topics:         [[:topic,   :default]],
    posts:          [[:post,    :default]],
    moderatorships: [[:moderatorship, :default]],
    monitorships:   [[:monitorship,   :default]],
  }.freeze

  def define_models(*args, &block)
    stubs = block ? StubCollector.new.tap { |c| c.instance_eval(&block) }.stubs : []
    extras = args.flat_map { |a| EXTRA_FIXTURE_SETS[a] || [] }

    before(:each) do
      sites(:default)
      # Pre-create the admin user BEFORE the default user, so
      # `users(:default)` isn't the first user on the site (otherwise
      # `set_first_user_as_admin` would auto-promote them and the
      # "non-admin user" tests would fail).
      users(:admin)
      users(:default)
      extras.each { |model, name| LegacyFixtures.fetch_for(model, name) }
      stubs.each do |klass, name, attrs|
        base_factory = klass.name.underscore.to_sym
        resolved = attrs.transform_values { |v| v.is_a?(Proc) ? instance_exec(&v) : v }
        # The base factory has a single canonical email/login; stubs that
        # don't override them would conflict with each other and with the
        # default user. Synthesize unique values from the stub's name
        # unless the spec supplied something explicit.
        if klass <= ActiveRecord::Base
          resolved[:email]     ||= "#{name}@stub.example.com" if klass.column_names.include?('email')
          resolved[:login]     ||= "stub-#{name}"             if klass.column_names.include?('login')
          resolved[:permalink] ||= "stub-#{name}"             if klass.column_names.include?('permalink')
          resolved[:host]      ||= "#{name}.stub.test"        if klass.column_names.include?('host')
        end
        cache = LegacyFixtures.send(:cache)
        cache[[base_factory, name]] ||= FactoryBot.create(base_factory, resolved)
      end
    end
    self
  end

  def model(*_args, &_block); end

  class StubCollector
    attr_reader :stubs
    def initialize; @stubs = []; end

    def model(klass, &block)
      # `model User` (no block) was a legacy "register this class as
      # part of the fixture set" declaration; we don't need it now.
      return unless block
      ModelBlock.new(klass, @stubs).instance_eval(&block)
    end
  end

  class ModelBlock
    def initialize(klass, buffer)
      @klass  = klass
      @buffer = buffer
    end

    # Two legacy forms:
    #   stub :foo, :attr => value          # named fixture `foo`
    #   stub :attr => value, :other => …   # default fixture (hash-as-name)
    def stub(name_or_attrs, attrs = {})
      if name_or_attrs.is_a?(Hash)
        @buffer << [@klass, :default, name_or_attrs]
      else
        @buffer << [@klass, name_or_attrs, attrs]
      end
    end

    # Time anchor used by legacy specs (e.g. `current_time - 132.days`).
    # Returns a real Time object so arithmetic works at declare-time.
    def current_time
      LegacyFixtures::CURRENT_TIME
    end

    # `:site => all_stubs(:other_site)` — defer to a Proc resolved at
    # before-each time so the referenced fixture has a chance to be
    # created in the same hook. Three name forms are supported:
    #
    #   all_stubs(:user)        — "the default user"  (model name)
    #   all_stubs(:other)       — fixture named :other in any model
    #   all_stubs(:other_site)  — fixture named :other_site in any model
    #
    # The bare-model form maps to that model's :default entry (which is
    # how the original plugin worked — `:user` was an alias for "the
    # canonical User instance").
    def all_stubs(name)
      ->(*) {
        if LegacyFixtures::NAMED_FACTORIES.key?(name)
          # `all_stubs(:user)` → users(:default)
          return LegacyFixtures.fetch_for(name, :default)
        end
        # Strip the model prefix if present, e.g. `:default_forum` →
        # forum(:default).
        if (m = name.to_s.match(/\A(\w+?)_(\w+)\z/))
          prefix, suffix = m.captures.map(&:to_sym)
          if LegacyFixtures::NAMED_FACTORIES[prefix]&.key?(suffix)
            return LegacyFixtures.fetch_for(prefix, suffix)
          end
          # Original plugin convention: `<name>_<model>` resolves to
          # that model's named fixture, e.g. `:other_site` →
          # `sites(:other)`. Try the suffix as a model key with the
          # prefix as the fixture name.
          if LegacyFixtures::NAMED_FACTORIES[suffix]&.key?(prefix)
            return LegacyFixtures.fetch_for(suffix, prefix)
          end
        end
        # Otherwise search every model bucket for the named fixture.
        LegacyFixtures::NAMED_FACTORIES.each do |model_key, names|
          return LegacyFixtures.fetch_for(model_key, name) if names.key?(name)
        end
        raise ArgumentError, "all_stubs(:#{name}) — no legacy fixture mapped"
      }
    end
  end
end

RSpec::Core::ExampleGroup.extend LegacyDefineModels
