# Provides the fixture-helper API the legacy specs (and the original
# vendored model_stubbing plugin) exposed: sites(:default), users(:admin),
# forums(:other), etc. Records are lazy-created via FactoryBot and memoized
# per RSpec example, so calling users(:default) twice in one example yields
# the same record (matching the original semantics).
#
# Each name maps to a factory: the bare name to its base factory, prefixed
# variants (:other, :admin, ...) to the corresponding subfactory.

require 'factory_bot'

module LegacyFixtures
  CURRENT_TIME = Time.utc(2007, 6, 15).freeze

  NAMED_FACTORIES = {
    site: {
      default: :site,
      other:   :other_site,
      new:     :new_site,
    },
    user: {
      default:   :user,
      activated: :activated_user,
      admin:     :admin_user,
      pending:   :pending_user,
      suspended: :suspended_user,
      other:     :other_user,
      bob:       :bob_user,
      rob:       :rob_user,
      robby:     :robby_user,
    },
    forum: {
      default:    :forum,
      other:      :other_forum,
      other_site: :other_site_forum,
    },
    topic: {
      default:     :topic,
      other:       :other_topic,
      sticky:      :sticky_topic,
      other_forum: :other_forum_topic,
    },
    post: {
      default:     :post,
      other:       :other_post,
      other_forum: :other_forum_post,
    },
    moderatorship: {
      default:        :moderatorship,
      default_other:  :default_other_moderatorship,
      other_default:  :other_default_moderatorship,
    },
    monitorship: {
      default:  :monitorship,
      inactive: :inactive_monitorship,
    },
  }.freeze

  class << self
    attr_accessor :current_example

    # Resolve a name to a record across all model categories. Factory
    # definition blocks use this for association references:
    #   site { LegacyFixtures.fetch(:site) }
    # Always routes through the per-example cache so the same record is
    # returned for repeated lookups within one example.
    def fetch(name)
      raise 'LegacyFixtures.fetch called outside of an example' unless current_example
      pair = NAMED_FACTORIES.find { |_, names| names.key?(name) }
      raise ArgumentError, "unknown legacy fixture name :#{name}" unless pair
      model, sym_map = pair
      cache[[model, name]] ||= FactoryBot.create(sym_map.fetch(name))
    end

    def cache
      @caches ||= {}
      @caches[current_example.object_id] ||= {}
    end

    def reset_for(example_instance)
      @caches&.delete(example_instance.object_id)
    end
  end

  module Helpers
    def current_time
      LegacyFixtures::CURRENT_TIME
    end

    LegacyFixtures::NAMED_FACTORIES.each_key do |model|
      collection_name = model.to_s.pluralize.to_sym
      define_method(collection_name) do |name|
        LegacyFixtures.fetch_for(model, name)
      end

      # new_user(:default, attrs) — build a fresh, unsaved record using the
      # named factory's attributes, optionally overlaying `attrs`. Mirrors the
      # singular-name accessor model_stubbing used to provide.
      define_method(:"new_#{model}") do |name, overrides = {}|
        LegacyFixtures.build_for(model, name, overrides)
      end
    end
  end
end

module LegacyFixtures
  class << self
    def fetch_for(model, name)
      cache[[model, name]] ||= build_default(model, name)
    end

    # `posts(:default)` reuses the post that the default Topic's
    # `after_create :create_initial_post` callback already created on
    # itself, rather than creating a *second* post on the same topic
    # (which would make `topics(:default).posts.size == 2` and break a
    # bunch of legacy assertions). Mirrors the original model_stubbing
    # plugin's behavior of treating the topic's initial post as the
    # default fixture.
    #
    # `reorder(:id)` is load-bearing: Topic.has_many :posts orders by
    # `created_at`, but factory-created posts can declare a `created_at`
    # in the past (e.g. `posts(:second)` at 2007), so the default order
    # would put them ahead of the real initial post. The initial post is
    # always the first row by id.
    def build_default(model, name)
      if model == :post && name == :default
        fetch_for(:topic, :default).posts.reorder(:id).first
      else
        FactoryBot.create(factory_sym(model, name))
      end
    end

    def build_for(model, name, overrides = {})
      FactoryBot.build(factory_sym(model, name), overrides)
    end

    private

    def factory_sym(model, name)
      NAMED_FACTORIES.fetch(model).fetch(name) do
        raise ArgumentError, "no factory mapped for #{model}(:#{name})"
      end
    end
  end
end

RSpec.configure do |config|
  config.include LegacyFixtures::Helpers
  config.include FactoryBot::Syntax::Methods

  config.before(:each) { LegacyFixtures.current_example = self }
  config.after(:each) do
    LegacyFixtures.reset_for(self)
    LegacyFixtures.current_example = nil
  end
end
