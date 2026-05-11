FactoryBot.define do
  factory :forum, aliases: [:default_forum] do
    name         { 'Default' }
    topics_count { 2 }
    posts_count  { 2 }
    position     { 1 }
    state        { 'public' }
    permalink    { 'default' }
    site         { LegacyFixtures.fetch_for(:site, :default) }

    factory :other_forum do
      name         { 'Other' }
      topics_count { 1 }
      posts_count  { 1 }
      position     { 0 }
      permalink    { 'other' }
    end

    # A forum that lives on the `:other` site (rather than the default
    # site). Used by spec/models/moderatorship_spec.rb to verify the
    # cross-site validation.
    factory :other_site_forum do
      name         { 'Other-Site' }
      topics_count { 0 }
      posts_count  { 0 }
      position     { 0 }
      permalink    { 'other-site' }
      site         { LegacyFixtures.fetch_for(:site, :other) }
    end
  end
end
