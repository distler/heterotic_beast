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
