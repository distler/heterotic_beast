require 'itex_stringsupport'

class UsersController < ApplicationController
  before_action :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge, :edit]
  before_action :find_user, :only => [:update, :show, :edit, :suspend, :unsuspend, :destroy, :purge]
  before_action :login_required, :only => [:settings, :update]

  # Brainbuster Captcha
  # before_action :create_brain_buster, :only => [:new]
  # before_action :validate_brain_buster, :only => [:create]

  def index
    users_scope = if admin?
                    case params[:status]
                    when 'active'
                      :users
                    when 'suspended'
                      :suspended_users
                    when 'pending'
                      :pending_users
                    else
                      :all_users
                    end
                  else
                    :users
                  end
    if params[:q]
      @q = params[:q].purify
      @users = current_site.send(users_scope).named_like(@q).paginate(:page => current_page)
    else
      @users = current_site.send(users_scope).paginate(:page => current_page)
    end
    respond_to do |format|
      format.html { set_content_type_header }
      format.js
    end
  end

  def show
    set_content_type_header
  end

  def new
    @user = User.new
  end

  def create
    cookies.delete :auth_token
    if params[:user]
      create_signup
    else
      create_password_reset
    end
  end

  def activate
    user = params[:activation_code].blank? ? nil :
      current_site.all_users.where(activation_code: params[:activation_code]).first
    if user
      self.current_user = user
      if user.state == 'pending'
        # Signup activation: pending → active.
        user.activate!
        flash[:notice] = "Signup complete!"
        redirect_back_or_default(:forums)
      else
        # Password-reset login: the one-time code is consumed here so it
        # can't be replayed. The user lands on /settings where they can
        # change their password.
        user.update_columns(activation_code: '')
        flash[:notice] = "Logged in. Update your password below if you forgot it."
        redirect_to settings_path
      end
    else
      redirect_back_or_default(:forums)
    end
  end

  def settings
    @user = current_user
    set_content_type_header
    render :action => "edit"
  end

  def edit
    set_content_type_header
  end

  def update
    @user = admin? ? find_user : current_user
    respond_to do |format|
      if @user.update(user_params)
        flash[:notice] = 'User account was successfully updated.'
        format.html { redirect_to(settings_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end


  def suspend
    @user.suspend! 
    flash[:notice] = "User was suspended."
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    flash[:notice] = "User was unsuspended."
    redirect_to users_path
  end

  def destroy
    @user.destroy
    flash[:notice] = "User was deleted."
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end

  def make_admin
    redirect_back_or_default(:forums) and return unless admin?
    @user = find_user
    @user.admin = (params.dig(:user, :admin) == "1")
    @user.save
    redirect_to @user
  end

  protected

    def create_signup
      @user = current_site.users.build(user_params)
      @user.save if @user.valid?
      @user.register! if @user.persisted?
      if @user.persisted?
        redirect_back_or_default(:login)
        flash[:notice] = I18n.t 'txt.activation_required',
          :default => "Thanks for signing up! Please click the link in your email to activate your account"
      else
        render :action => 'new'
      end
    end

    # "E-mail me the link" on /login. Find the user by email; if they
    # exist, generate a fresh one-time activation_code and email them a
    # link. The link goes through `#activate`, which (for already-active
    # users) clears the code, logs them in, and lands them on /settings.
    # We always show the same notice so this can't be used to probe
    # which emails are on file.
    def create_password_reset
      email = params[:email].to_s.purify.strip.downcase
      user  = current_site.all_users.find_by(email: email) if email.present?
      if user
        user.update_columns(
          activation_code: Digest::SHA1.hexdigest("#{Time.now.to_f}-#{user.id}-#{SecureRandom.hex}")
        )
        UserMailer.password_reset(user).deliver
      end
      redirect_to login_path
      flash[:notice] = I18n.t 'txt.password_reset_sent',
        :default => "If that address is on file, we've sent a login link to it."
    end

    def find_user
      @user = if admin?
        current_site.all_users.find params[:id]
      elsif current_user && params[:id] == current_user.id
        current_user
      else
        current_site.users.find params[:id]
      end or raise ActiveRecord::RecordNotFound
    end

    def authorized?
      admin? || params[:id].blank? || params[:id] == current_user.id.to_s
    end

    def render_or_redirect_for_captcha_failure
      render :action => 'new'
    end

    def user_params
      permitted = [:login, :email, :password, :password_confirmation, :openid_url,
                   :display_name, :bio, :website]
      permitted += [:admin, :remember_token, :remember_token_expires_at] if admin?
      params.fetch(:user, {}).permit(*permitted)
    end
end
