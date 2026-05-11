FactoryBot.define do
  factory :site, aliases: [:default_site] do
    name { 'default' }
    host { '' }
    created_at { LegacyFixtures::CURRENT_TIME - 5.years }

    factory :other_site do
      name { 'other' }
      host { 'other.test.host' }
    end

    factory :new_site do
      name { 'new site' }
      host { 'new.test.host' }
    end
  end
end
