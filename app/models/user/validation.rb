module User::Validation
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_login_and_email

    validates_presence_of     :login, :email
    # Password length only enforced when the form supplied one; lets
    # OpenID-only signups and the legacy `password_digest IS NULL`
    # rows (from the bcrypt-migration cutover) save without a password.
    validates_presence_of     :password,                   :if => :password_required?
    validates_presence_of     :password_confirmation,      :if => :password_required?
    validates_length_of       :password, :within => 6..40, :if => :password_required?
    validates_confirmation_of :password,                   :if => :password_required?
    validates_length_of       :login,    :within => 3..40
    validates_length_of       :email,    :within => 3..100
    validates_uniqueness_of   :email, :scope => :site_id
    validates_uniqueness_of   :login, :case_sensitive => false, :scope => :site_id
    validates_uniqueness_of   :openid_url, :case_sensitive => false, :allow_nil => true

    before_create :set_first_user_as_admin
  end

  # Drop-in replacement for the legacy `authenticated?(password)` —
  # `has_secure_password`'s `#authenticate` returns the user or false;
  # adapt to true/false. Guards against `password_digest == nil`
  # (which `BCrypt::Password.new(nil)` would otherwise raise on).
  def authenticated?(password)
    return false if password_digest.blank?
    authenticate(password) ? true : false
  end

  protected

    def using_openid
      !openid_url.blank?
    end

    def password_required?
      # Only require a password when:
      #   - we haven't stored one yet AND the user isn't using OpenID
      #   - or the form is changing the password
      return false if using_openid
      password_digest.blank? || password.present?
    end

    def set_first_user_as_admin
      # Count via the model scope, NOT `site.users.size`. The latter
      # caches the CollectionProxy on the in-memory Site and would
      # report 0 forever once it was loaded empty (e.g. during the
      # very-first user's creation), even after subsequent users
      # land — promoting every later user to admin too.
      return unless site_id
      self.admin = true if User.where(site_id: site_id, state: 'active').none?
    end

    def normalize_login_and_email
      login.strip! if login
      email.downcase! && email.strip! if email
      return true
    end
end
