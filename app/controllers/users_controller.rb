require 'itex_stringsupport'

class UsersController < ApplicationController
  before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge, :edit]
  before_filter :find_user, :only => [:update, :show, :edit, :suspend, :unsuspend, :destroy, :purge]
  before_filter :login_required, :only => [:settings, :update]

  # Brainbuster Captcha
  # before_filter :create_brain_buster, :only => [:new]
  # before_filter :validate_brain_buster, :only => [:create]

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
    @user = params[:user] ?
             current_site.users.build(params[:user]) :
             # current_site.users.build(User.where(:email => params[:email]).first.login)    
             User.where(:email => params[:email].purify).first
    @user.save if @user.valid?
    @user.register if @user.valid?
    unless @user.new_record?
      redirect_back_or_default(:login)
      flash[:notice] = I18n.t 'txt.activation_required', 
        :default => "Thanks for signing up! Please click the link in your email to activate your account"
    else
      render :action => 'new'
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
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User account was successfully updated.'
        format.html { redirect_to(settings_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def activate
    # not sure why this was using a symbol. Let's use the real false.
    self.current_user = params[:activation_code].blank? ? false : current_site.all_users.find_in_state(:first, :pending, :conditions => {:activation_code => params[:activation_code]})
    if logged_in?
      current_user.activate!
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default(:forums)
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
    User.destroy(@user)
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
    @user.admin = (params[:user][:admin] == "1")
    @user.save
    redirect_to @user
  end

  protected

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
end
