class ModeratorshipsController < ApplicationController
  def create
    @moderatorship = Moderatorship.new(moderatorship_params)

    respond_to do |format|
      if @moderatorship.save
        flash[:notice] = 'Moderatorship was successfully created.'
        format.html { redirect_to(@moderatorship.user) }
        format.xml  { render :xml  => @moderatorship, :status => :created, :location => @moderatorship }
      else
        flash[:error] = "Moderatorship could not be created: #{@moderatorship.errors.full_messages.to_sentence}" unless @moderatorship.forum_id.blank?
        format.html { redirect_to(@moderatorship.user) }
        format.xml  { render :xml  => @moderatorship.errors.to_hash, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @moderatorship = Moderatorship.find(params[:id])
    @moderatorship.destroy

    respond_to do |format|
      format.html { redirect_to(@moderatorship.user) }
      format.xml  { head :ok }
    end
  end

  private

    def moderatorship_params
      params.fetch(:moderatorship, {}).permit(:user_id, :forum_id)
    end
end
