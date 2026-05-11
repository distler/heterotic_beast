# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'authenticated_system'

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include ActionView::RecordIdentifier

  helper_method :current_page
  before_action :login_required, :only => [:new, :edit, :create, :update, :destroy]

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'e125a4be589f9d81263920581f6e4182'

  # raised in #current_site
  rescue_from Site::UndefinedError do |e|
    redirect_to new_site_path
  end

  def current_page
    @page ||= [1, params[:page].to_i].max
  end

  def set_content_type_header
    response.charset = 'utf-8'
      if request.user_agent =~ /Validator/ or request.env.include?('HTTP_ACCEPT') &&
           Mime::Type.parse(request.env["HTTP_ACCEPT"]).include?(Mime[:xhtml])
        response.content_type = Mime[:xhtml]
      elsif request.user_agent =~ /MathPlayer/
        response.charset = nil
        response.content_type = Mime[:xhtml]
        response.extend(MathPlayerHack)
      else
        response.content_type = Mime[:html]
      end
  end

end

module MathPlayerHack
    def charset=(encoding)
      self.headers["Content-Type"] = "#{content_type || Mime[:html]}"
    end
end
