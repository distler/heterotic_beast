# coding: utf-8
class UserMailer < ActionMailer::Base
  default :from => "your_domain@example.com"

  def signup_notification(user)
    @user = user
    host = user.site.host
    host << ENV['RAILS_RELATIVE_URL_ROOT'] if ENV['RAILS_RELATIVE_URL_ROOT'] 
    @url = activate_url(user.activation_code, :host => host)
    mail :to => user.email, :from => user.site.admin.email, :subject => subject(user, "Please activate your new account")
  end

  def activation(user)
    @user = user
    @url = root_url(:host => user.site.host)
    mail :to => user.email, :from => user.site.admin.email, :subject => subject(user, "Your account has been activated!")
  end

  protected

    def subject(user, text)
      [user.site.name, text] * " – "
    end
end
