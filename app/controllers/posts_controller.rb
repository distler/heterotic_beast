require 'instiki_stringsupport'

class PostsController < ApplicationController
  before_filter :find_parents
  before_filter :find_post, :only => [:edit, :update, :destroy]

  cache_sweeper :posts_sweeper, :only => [:create, :update, :destroy]

  # /posts
  # /users/1/posts
  # /forums/1/posts
  # /forums/1/topics/1/posts
  def index
    @monitored = logged_in? && params[:monitored]
    @q = params[:q] ? params[:q].purify : nil
    @posts = (@parent ? @parent.posts : current_site.posts).search(@q, :page => current_page)
    @monitored_posts = logged_in? ? (@parent ? @parent.posts : current_site.posts).search_monitored(current_user.id, @q, :page => current_page) : nil
    @users = @user ? {@user.id => @user} : User.index_from(@posts)
    respond_to do |format|
      format.html { set_content_type_header } # index.html.erb
      format.atom # index.atom.builder
      format.xml  { render :xml  => @posts }
      format.js
    end
  end

  def show
    respond_to do |format|
      format.html do
         set_content_type_header
         redirect_to forum_topic_path(@forum, @topic)
      end
      format.xml  do
        find_post
        render :xml  => @post
      end
    end
  end

  def edit
    respond_to do |format|
      format.html # edit.html.erb
      format.js
    end
  end

  def create
    @post = current_user.reply @topic, params[:post][:body]

    respond_to do |format|
      if @post.new_record?
        format.html { redirect_to forum_topic_path(@forum, @topic) }
        format.xml  { render :xml  => @post.errors, :status => :unprocessable_entity }
      else
        flash[:notice] = 'Post was successfully created.'
        format.html { redirect_to(forum_topic_path(@forum, @topic, {:anchor => dom_id(@post), :page => @topic.last_page})) }
        format.xml  { render :xml  => @post, :status => :created, :location => forum_topic_post_url(@forum, @topic, @post) }
      end
    end
  end

  def update
    respond_to do |format|
      if @post.update_attributes(params[:post])
        flash[:notice] = 'Post was successfully updated.'
        format.html { redirect_to(forum_topic_path(@forum, @topic, {:anchor => dom_id(@post), :page => @topic.post_page(@post)})) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml  => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @post.destroy

    respond_to do |format|
      format.html do
          if @forum.topics.exists?(@topic)
            redirect_to(forum_topic_path(@forum, @topic))
          else
            redirect_to(@forum)
          end
        end
      format.xml  { head :ok }
    end
  end

  protected

    def find_parents
      if params[:user_id]
        @parent = @user = User.find(params[:user_id])
      elsif params[:forum_id]
        @parent = @forum = Forum.find_by_permalink(params[:forum_id])
        @parent = @topic = @forum.topics.find_by_permalink(params[:topic_id]) if params[:topic_id]
      end
    end

    def find_post
      post = @topic.posts.find(params[:id])
      if post.user == current_user || current_user.admin? || @forum.moderators.include?(current_user)
        @post = post
      else
        raise ActiveRecord::RecordNotFound
      end
    end
end
