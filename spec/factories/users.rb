FactoryBot.define do
  factory :user, aliases: [:default_user] do
    login                     { 'normal-user' }
    email                     { 'normal-user@example.com' }
    state                     { 'active' }
    # Plain-text "test" stored via bcrypt by has_secure_password. The
    # legacy SHA-1 `crypted_password` + `salt` columns are gone.
    password                  { 'test99' }
    password_confirmation     { 'test99' }
    created_at                { LegacyFixtures::CURRENT_TIME - 5.days }
    remember_token            { 'foo-bar' }
    remember_token_expires_at { LegacyFixtures::CURRENT_TIME + 5.days }
    # Unique per record. Original fixtures hard-coded one shared value
    # which the legacy `activate` action got away with because of its
    # `state: 'pending'` filter; broadening the lookup for the password-
    # reset flow surfaces the collision.
    activation_code           { Digest::SHA1.hexdigest("default-#{SecureRandom.hex}") }
    activated_at              { LegacyFixtures::CURRENT_TIME - 4.days }
    posts_count               { 3 }
    permalink                 { 'normal-user' }
    site                      { LegacyFixtures.fetch_for(:site, :default) }

    factory :activated_user do
      login                     { 'activated-user' }
      email                     { 'activated-user@example.com' }
      remember_token            { 'foo-bar-activated' }
      activation_code           { nil }
      permalink                 { 'activated-user' }
    end

    factory :admin_user do
      login          { 'admin-user' }
      email          { 'admin-user@example.com' }
      remember_token { 'blah' }
      admin          { true }
    end

    factory :pending_user do
      login          { 'pending-user' }
      email          { 'pending-user@example.com' }
      state          { 'pending' }
      activated_at   { nil }
      remember_token { 'asdf' }
    end

    factory :suspended_user do
      login          { 'suspended-user' }
      email          { 'suspended-user@example.com' }
      state          { 'suspended' }
      remember_token { 'dfdfd' }
    end

    factory :other_user do
      login { 'other-user' }
      email { '@example.com' }
    end

    # Search-test fixtures for `users_controller_spec.rb` "GET #index
    # with search parameter". Names are arranged so a search for "bob"
    # matches Bob's display_name and Rob's login but NOT Robby (whose
    # login starts with "robby").
    factory :bob_user do
      login         { 'robert' }
      email         { 'robert@example.com' }
      display_name  { 'Bob' }
      permalink     { 'robert' }
    end

    factory :rob_user do
      login         { 'bob' }
      email         { 'bob2@example.com' }
      display_name  { 'Robert' }
      permalink     { 'bob' }
    end

    factory :robby_user do
      login         { 'robby' }
      email         { 'robby@example.com' }
      display_name  { 'Robby' }
      permalink     { 'robby' }
    end
  end
end
