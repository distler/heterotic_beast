FactoryBot.define do
  factory :post, aliases: [:default_post] do
    body       { 'initial' }
    created_at { LegacyFixtures::CURRENT_TIME - 5.days }
    topic      { LegacyFixtures.fetch_for(:topic, :default) }
    forum      { LegacyFixtures.fetch_for(:forum, :default) }
    user       { LegacyFixtures.fetch_for(:user, :default) }
    site       { LegacyFixtures.fetch_for(:site, :default) }

    factory :other_post do
      body       { 'other' }
      created_at { LegacyFixtures::CURRENT_TIME - 13.days }
      topic      { LegacyFixtures.fetch_for(:topic, :other) }
    end

    factory :other_forum_post do
      forum { LegacyFixtures.fetch_for(:forum, :other) }
      topic { LegacyFixtures.fetch_for(:topic, :other_forum) }
    end
  end
end
