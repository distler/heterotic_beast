module User::States
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm column: 'state', whiny_transitions: false do
      state :passive, initial: true
      # NOTE: AASM 5 saves the record *between* before_enter and after_enter
      # for the bang form of an event. Attribute mutations therefore must go
      # in before_enter (so they get persisted); side effects like email go
      # in after_enter. The original code stuffed everything into a single
      # callback because acts_as_state_machine saved *after* callbacks ran.
      state :pending,   before_enter: :prepare_for_activation, after_enter: :send_signup_notification
      state :active,    before_enter: :prepare_for_activated,  after_enter: :send_activation_notification
      state :suspended
      state :deleted,   before_enter: :prepare_for_deleted

      event :register do
        transitions from: :passive, to: :pending,
          guard: -> { !(password_digest.blank? && password.blank?) }
      end

      event :activate do
        transitions from: :pending, to: :active
      end

      event :suspend do
        transitions from: [:passive, :pending, :active], to: :suspended, guard: :remove_moderatorships
      end

      event :delete do
        transitions from: [:passive, :pending, :active, :suspended], to: :deleted
      end

      event :unsuspend do
        transitions from: :suspended, to: :active,  guard: -> { !activated_at.blank? }
        transitions from: :suspended, to: :pending, guard: -> { !activation_code.blank? }
        transitions from: :suspended, to: :passive
      end
    end
  end

  class_methods do
    def authenticate(login, password)
      return nil if login.blank? || password.blank?
      # Case-insensitive login lookup, matching the case-insensitive
      # uniqueness validation. Required for SQLite (where TEXT `=` is
      # case-sensitive); MySQL's default collation hid this in production.
      u = where(state: 'active').where('LOWER(login) = ?', login.downcase).first
      u && u.authenticated?(password) ? u : nil
    end
  end

  protected

    def prepare_for_activation
      self.deleted_at = nil
      self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by { rand }.join)
    end

    def send_signup_notification
      UserMailer.signup_notification(self).deliver
    end

    def prepare_for_activated
      @activated = true
      self.activated_at = Time.now.utc
      self.deleted_at = nil
      self.activation_code = ''
    end

    def send_activation_notification
      UserMailer.activation(self).deliver unless using_openid
    end

    def prepare_for_deleted
      self.deleted_at = Time.now.utc
    end

    def remove_moderatorships
      moderatorships.delete_all
    end
end
