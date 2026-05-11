FactoryBot.define do
  factory :monitorship, aliases: [:default_monitorship] do
    user   { LegacyFixtures.fetch_for(:user, :default) }
    topic  { LegacyFixtures.fetch_for(:topic, :default) }
    active { true }

    factory :inactive_monitorship do
      topic  { LegacyFixtures.fetch_for(:topic, :other) }
      active { false }
    end
  end
end
