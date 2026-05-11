FactoryBot.define do
  factory :moderatorship, aliases: [:default_moderatorship] do
    user  { LegacyFixtures.fetch_for(:user, :default) }
    forum { LegacyFixtures.fetch_for(:forum, :other) }

    factory :default_other_moderatorship do
      user  { LegacyFixtures.fetch_for(:user, :default) }
      forum { LegacyFixtures.fetch_for(:forum, :other) }
    end

    factory :other_default_moderatorship do
      user  { LegacyFixtures.fetch_for(:user, :other) }
    end
  end
end
