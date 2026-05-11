module User::Activation
  extend ActiveSupport::Concern

  included do
    # `Authentication` still provides `make_token` / `secure_digest`
    # used by the cookie-remember-me code path. `ByPassword` has been
    # removed — password storage is now `has_secure_password` (bcrypt).
    include Authentication
    include Authentication::ByCookieToken

    after_create :set_first_user_as_activated
  end

  def set_first_user_as_activated
    # Bootstrap path: auto-activate only the very first user on a fresh
    # site (so there's someone to log in as). Subsequent signups must go
    # through pending → email confirmation. The original `<= 1` counted
    # the existing admin as "first," which auto-activated the second user
    # and skipped the activation email entirely.
    #
    # Count via the model scope rather than `site.users.count` to avoid
    # the cached-association staleness that bites the parallel callback
    # `set_first_user_as_admin`.
    return unless site_id || site.nil?
    return register! && activate! if site.nil?
    register! && activate! if User.where(site_id: site_id, state: 'active').where.not(id: id).none?
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil? || activation_code.blank?
  end
end
