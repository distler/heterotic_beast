FactoryBot.define do
  factory :topic, aliases: [:default_topic] do
    title           { 'initial' }
    body            { 'initial body' }
    hits            { 0 }
    sticky          { 0 }
    posts_count     { 1 }
    last_post_id    { 1000 }
    last_updated_at { LegacyFixtures::CURRENT_TIME - 5.days }
    permalink       { 'initial' }
    created_at      { LegacyFixtures::CURRENT_TIME - 3.years }
    forum           { LegacyFixtures.fetch_for(:forum, :default) }
    user            { LegacyFixtures.fetch_for(:user, :default) }
    site            { LegacyFixtures.fetch_for(:site, :default) }

    # The topic's `after_create :create_initial_post` callback creates a
    # Post; that Post's own `after_create :update_cached_fields` callback
    # rewrites the topic's `last_updated_at` to Time.now. That clobbering
    # breaks specs that rely on the declared value to control sort order.
    # Restore `last_updated_at` after the cascade so ordering by it is
    # deterministic. (Subfactories that override `last_updated_at` get the
    # callback inherited, and the evaluator sees the overridden value.)
    after(:create) do |topic, evaluator|
      topic.update_columns(last_updated_at: evaluator.last_updated_at)
    end

    factory :other_topic do
      title           { 'Other' }
      last_updated_at { LegacyFixtures::CURRENT_TIME - 4.days }
      permalink       { 'other' }
    end

    factory :other_forum_topic do
      forum { LegacyFixtures.fetch_for(:forum, :other) }
    end

    factory :sticky_topic do
      sticky          { 1 }
      last_updated_at { LegacyFixtures::CURRENT_TIME - 132.days }
    end
  end
end
