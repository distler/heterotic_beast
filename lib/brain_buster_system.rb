# Inlined from the Rails-2.3-style brain_buster plugin (vendor/plugins/brain_buster).
# Mixed into ActionController::Base in config/initializers/brain_buster.rb.
require 'digest/sha2'

module BrainBusterSystem
  def self.included(obj)
    obj.helper_method :captcha_passed?, :last_captcha_attempt_failed?
    obj.class_eval do
      @@brain_buster_salt ||= 'fGr0FXmYQCuW4TiQj/x3yPBTp5lcJ9l6DbO8CUpReDk='
      @@brain_buster_failure_message = 'Your captcha answer failed - please try again.'
      @@brain_buster_enabled = true
      cattr_accessor :brain_buster_salt, :brain_buster_failure_message, :brain_buster_enabled
    end
  end

  def create_brain_buster
    raise_if_salt_isnt_set
    return true if captcha_passed? || !brain_buster_enabled
    @captcha = find_brain_buster
  end

  def validate_brain_buster
    raise_if_salt_isnt_set
    return true if captcha_passed? || !brain_buster_enabled
    return captcha_failure unless params[:captcha_id] && params[:captcha_answer]

    captcha = @captcha = find_brain_buster
    is_success = captcha.attempt?(params[:captcha_answer])
    set_captcha_status(is_success)
    is_success ? captcha_success : captcha_failure
  end

  def self.encrypt(str, salt)
    Digest::SHA256.hexdigest("--#{str}--#{salt}--")
  end

  def captcha_passed?
    cookies[:captcha_status] == encrypt('passed')
  end
  alias captcha_previously_passed? captcha_passed?

  def last_captcha_attempt_failed?
    flash[:failed_captcha]
  end

  protected

  def captcha_success
    true
  end

  def captcha_failure
    set_captcha_failure_message
    render_or_redirect_for_captcha_failure
  end

  def render_or_redirect_for_captcha_failure
    render text: brain_buster_failure_message, layout: true
  end

  def set_captcha_failure_message
    flash[:error] = brain_buster_failure_message
  end

  def set_captcha_status(is_success)
    status = is_success ? 'passed' : 'failed'
    flash[:failed_captcha] = params[:captcha_id] unless is_success
    cookies[:captcha_status] = encrypt(status)
  end

  def raise_if_salt_isnt_set
    raise 'You have to set the Brain Buster salt to something other then the default.' if ActionController::Base.brain_buster_salt.blank?
  end

  def find_brain_buster
    BrainBuster.find_random_or_previous(params[:captcha_id] || flash[:failed_captcha])
  end

  private

  def encrypt(str)
    BrainBusterSystem.encrypt(str, brain_buster_salt)
  end
end
