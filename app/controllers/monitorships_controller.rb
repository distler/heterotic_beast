class MonitorshipsController < ApplicationController
  before_action :login_required

  def create
    @monitorship = Monitorship.find_or_initialize_by(user_id: current_user.id, topic_id: params[:topic_id])
    topic = Topic.find(params[:topic_id])
    @monitorship.update_attribute :active, true
    respond_to do |format|
      format.html { redirect_to forum_topic_path(params[:forum_id], topic) }
      format.js   { head :ok }
    end
  end

  def destroy
    Monitorship.where(:user_id => current_user.id, :topic_id => params[:topic_id]).update_all(:active => false)
    topic = Topic.find(params[:topic_id])
    respond_to do |format|
      format.html { redirect_to forum_topic_path(params[:forum_id], topic) }
      format.js   { head :ok }
    end
  end
end
