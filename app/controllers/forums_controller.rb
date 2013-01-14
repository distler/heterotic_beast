class ForumsController < ApplicationController
  before_filter :admin_required, :except => [:index, :show]
  before_filter :find_forum, :only => [:show, :edit, :update, :destroy]

  # GET /forums
  # GET /forums.xml
  def index
    # reset the page of each forum we have visited when we go back to index
    session[:forums_page] = nil

    @forums = admin? ? current_site.all_forums : current_site.ordered_forums

    respond_to do |format|
      format.html { set_content_type_header } # index.html.erb
      format.xml  { render :xml => @forums }
    end
  end

  # GET /forums/1
  # GET /forums/1.xml
  def show
    (session[:forums] ||= {})[@forum.id] = Time.now.utc
    (session[:forums_page] ||= Hash.new(1))[@forum.id] = current_page if current_page > 1
    @monitored = logged_in? && params[:monitored]
    @topics ||= @forum.topics.paginate :page => current_page
    @monitored_topics ||= logged_in? ? 
        (@forum.monitored_topics(current_user).paginate :page => current_page) :
        nil

    respond_to do |format|
      format.html do # show.html.erb
        set_content_type_header
      end
      format.xml  { render :xml => @forum }
      format.js
    end
  end
  
  # GET /forums/new
  # GET /forums/new.xml
  def new
    @forum = current_site.forums.new

    respond_to do |format|
      format.html {set_content_type_header }# new.html.erb
      format.xml  { render :xml => @forum }
    end
  end

  # GET /forums/1/edit
  def edit
  end

  # POST /forums
  # POST /forums.xml
  def create
    @forum = current_site.forums.build(params[:forum])

    respond_to do |format|
      if @forum.save
        flash[:notice] = I18n.t 'txt.forum_created', :default => 'Forum was successfully created.'
        format.html { redirect_to(@forum) }
        format.xml  { render :xml => @forum, :status => :created, :location => @forum }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /forums/1
  # PUT /forums/1.xml
  def update

    respond_to do |format|
      if @forum.update_attributes(params[:forum])
        flash[:notice] = I18n.t 'txt.forum_updated', :default => 'Forum was successfully updated.'
        format.html { redirect_to(@forum) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /forums/1
  # DELETE /forums/1.xml
  def destroy
    @forum.destroy

    respond_to do |format|
      format.html { redirect_to(forums_path) }
      format.xml  { head :ok }
    end
  end

  protected

    def find_forum
      @forum = admin? ? current_site.all_forums.find_by_permalink!(params[:id]) : current_site.forums.find_by_permalink!(params[:id])
    end

end
