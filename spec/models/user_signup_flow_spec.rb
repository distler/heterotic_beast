require File.dirname(__FILE__) + '/../spec_helper'

# Regression tests for the user-signup → activation → login flow, which
# broke in several stacked ways during the Rails 3.2 → 4.2 upgrade. Each
# fix is pinned by its own example; together they exercise the end-to-end
# happy path of "sign up via the form, click the activation link in the
# email, then log in with the chosen password."

# Helper: ensure sites(:default) already has an active user, so the
# `set_first_user_as_activated` bootstrap callback doesn't fire on the
# test users we build. (The factory's :user record satisfies this.)
def ensure_default_site_seeded
  sites(:default)
  users(:default)
end

describe "Site#users association (build state propagation)" do
  before { ensure_default_site_seeded }

  # Pre-fix:
  #   has_many :users, -> { where(state: 'active') }
  # Rails 4 propagates equality conditions on association scopes as default
  # attributes on `.build`/`.new`. So `site.users.build(...)` produced a
  # User with state='active' before AASM's `:passive` initial could apply,
  # which broke the entire activation flow. The fix uses a SQL-fragment
  # form (`-> { where("users.state = ?", "active") }`) which does not
  # propagate.
  it "does NOT pre-set state on records built through the active-users scope" do
    user = sites(:default).users.build(login: 'fresh', email: 'fresh@example.com',
                                       password: 'secret123', password_confirmation: 'secret123')
    expect(user.state).to eq('passive')
  end

  it "still filters loaded records to state='active'" do
    expect(sites(:default).users.to_sql).to match(/state\s*=\s*'active'/i)
  end
end

describe "User AASM event :register guard arity" do
  before { ensure_default_site_seeded }

  # Pre-fix: `guard: ->(u) { !(u.crypted_password.blank? && u.password.blank?) }`
  # AASM 5 evaluates guards via `instance_exec` (no args; `self` is the
  # user), so a 1-arity lambda raised `ArgumentError: wrong number of
  # arguments (given 0, expected 1)`. The fix is a 0-arity lambda using
  # implicit-self method calls.
  it "does not raise ArgumentError when the bang form is invoked" do
    User.where(login: 'arity-check').destroy_all
    u = sites(:default).users.build(login: 'arity-check', email: 'arity@example.com',
                                    password: 'secret123', password_confirmation: 'secret123')
    u.save!
    expect { u.register! }.not_to raise_error
    User.where(login: 'arity-check').destroy_all
  end
end

describe "User AASM persistence on transition (5.x callback timing)" do
  # AASM 5 saves between `before_enter` and `after_enter`. Attribute
  # mutations therefore have to happen in `before_enter` to be persisted.
  # The original `do_activation` / `do_activate` set
  # activation_code/activated_at in a single `after_enter`, so the
  # mutations stayed in memory only — the DB row had state='pending' but
  # activation_code=nil, breaking the click-the-link lookup.

  before do
    ensure_default_site_seeded
    User.where(login: 'persist-check').destroy_all
    @user = sites(:default).users.build(login: 'persist-check', email: 'persist@example.com',
                                        password: 'secret123', password_confirmation: 'secret123')
    @user.save!
    ActionMailer::Base.deliveries.clear
  end

  after { User.where(login: 'persist-check').destroy_all }

  it "persists activation_code on `register!` (transition to :pending)" do
    @user.register!
    fresh = User.find(@user.id)
    expect(fresh.state).to            eq('pending')
    expect(fresh.activation_code).to  be_present
    expect(fresh.activation_code).to  eq(@user.activation_code)
  end

  it "sends the signup_notification email after register!" do
    @user.register!
    last = ActionMailer::Base.deliveries.last
    expect(last).not_to be_nil
    expect(last.subject).to match(/please activate your new account/i)
  end

  it "persists activated_at + clears activation_code on `activate!`" do
    @user.register!
    pending = User.where(state: 'pending', activation_code: @user.activation_code).first
    expect(pending).to eq(@user)

    pending.activate!
    fresh = User.find(pending.id)
    expect(fresh.state).to            eq('active')
    expect(fresh.activated_at).not_to be_nil
    expect(fresh.activation_code).to  eq('')
  end
end

describe "Site bootstrap: set_first_user_as_activated" do
  # Pre-fix: `register! && activate! if site.nil? || site.users.count <= 1`
  # — the `<= 1` counted the existing admin as "first," so the SECOND
  # user signed up was auto-activated and the activation email was the
  # already-active one rather than the signup_notification. Fix is
  # `count.zero?` (mirrors `set_first_user_as_admin`).

  it "auto-activates the FIRST user on a fresh site (bootstrap path)" do
    site = Site.create!(name: 'bootstrap', host: 'bootstrap.test')
    expect(site.users.count).to eq(0)
    user = site.all_users.create!(login: 'first-user', email: 'first@example.com',
                                  password: 'secret123', password_confirmation: 'secret123')
    expect(user.reload.state).to eq('active')
  end

  it "does NOT auto-activate the second user on a site that already has one" do
    site = Site.create!(name: 'second', host: 'second.test')
    site.all_users.create!(login: 'first',  email: 'first@example.com',
                           password: 'secret123', password_confirmation: 'secret123')
    expect(site.users.count).to eq(1)

    second = site.all_users.create!(login: 'second', email: 'second@example.com',
                                    password: 'secret123', password_confirmation: 'secret123')
    expect(second.reload.state).to eq('passive')
  end
end

# Regression: `set_first_user_as_admin` used `site.users.size`, which
# caches the CollectionProxy on the in-memory Site. The first time the
# callback ran (during the very first user's before_create), the proxy
# loaded as empty and stayed cached at size=0 — so every subsequent
# user created against the same in-memory Site instance was also
# auto-promoted to admin. Pin via the User scope instead, and verify
# only the first user on a fresh site becomes admin.
describe "User#set_first_user_as_admin (cached-association regression)" do
  it "promotes only the very first user on a fresh site" do
    site  = Site.create!(name: 'admin-bootstrap', host: 'admin-bootstrap.test')
    first = site.all_users.create!(login: 'first',  email: 'first@example.com',
                                   password: 'secret123', password_confirmation: 'secret123',
                                   state: 'active')
    expect(first.reload.admin).to be true

    second = site.all_users.create!(login: 'second', email: 'second@example.com',
                                    password: 'secret123', password_confirmation: 'secret123',
                                    state: 'active')
    expect(second.reload.admin).to be false
  end

  it "still uses the same in-memory Site for both creations (the bug condition)" do
    site = Site.create!(name: 'shared-site', host: 'shared.test')
    a = site.all_users.create!(login: 'aaa', email: 'a@example.com',
                               password: 'secret123', password_confirmation: 'secret123',
                               state: 'active')
    b = site.all_users.create!(login: 'bbb', email: 'b@example.com',
                               password: 'secret123', password_confirmation: 'secret123',
                               state: 'active')
    expect(a.reload.admin).to be true
    expect(b.reload.admin).to be false
  end
end

describe "User.authenticate case-insensitive login" do
  # Pre-fix: `where(state: 'active', login: login).first` was a
  # case-sensitive equality match. The login form does
  # `params[:login].downcase`, but `normalize_login_and_email` only
  # strips whitespace — so a user signed up as "Foo Bar" was looked up
  # as "foo bar" and never matched under SQLite (case-sensitive `=`).
  # The fix uses `LOWER(login) = LOWER(?)`, matching the case-insensitive
  # uniqueness validation.

  before do
    ensure_default_site_seeded
    User.where(login: 'CaseTest').destroy_all
    @user = sites(:default).users.build(login: 'CaseTest', email: 'casetest@example.com',
                                        password: 'secret123', password_confirmation: 'secret123')
    @user.save!
    @user.register!
    pending = sites(:default).all_users.where(state: 'pending', activation_code: @user.activation_code).first
    pending.activate!
  end

  after { User.where(login: 'CaseTest').destroy_all }

  %w[CaseTest casetest CASETEST CaSeTeSt].each do |name|
    it "matches login=#{name.inspect} (any case)" do
      expect(User.authenticate(name, 'secret123')).to eq(@user)
    end
  end

  it "still rejects an incorrect password" do
    expect(User.authenticate('CaseTest', 'wrongpw')).to be_nil
  end

  it "rejects a non-existent login" do
    expect(User.authenticate('nobody-here', 'secret123')).to be_nil
  end

  it "rejects blank login or password" do
    expect(User.authenticate('',         'secret123')).to be_nil
    expect(User.authenticate('CaseTest', '')).to          be_nil
  end
end
