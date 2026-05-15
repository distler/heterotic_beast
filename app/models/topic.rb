class Topic < ApplicationRecord
  include User::Editable

  before_validation :set_default_attributes, :on => :create

  after_create   :create_initial_post
  before_update  :check_for_moved_forum
  after_update   :set_post_forum_id
  before_destroy :count_user_posts_for_counter_cache
  after_destroy  :update_cached_forum_and_user_counts

  # creator of forum topic
  belongs_to :user

  # creator of recent post
  belongs_to :last_user, :class_name => "User"

  belongs_to :forum, :counter_cache => true

  # forum's site, set by callback
  belongs_to :site, :counter_cache => true

  has_many :posts,       -> { order("#{Post.table_name}.created_at") }, dependent: :delete_all
  has_one  :recent_post, -> { order("#{Post.table_name}.created_at DESC") }, class_name: 'Post'

  # `has_many :posts` carries an `ORDER BY posts.created_at` default scope,
  # which propagates into `voices` and conflicts with `DISTINCT` under MySQL's
  # ONLY_FULL_GROUP_BY (Trilogy::ProtocolError 3065). Unscope the order here.
  has_many :voices, -> { unscope(:order).distinct }, through: :posts, source: :user
  
  has_many :monitorships, :dependent => :delete_all
  has_many :monitoring_users, -> { where("#{Monitorship.table_name}.active" => true) }, through: :monitorships, source: :user
  
  validates_presence_of :user_id, :site_id, :forum_id, :title
  validates_presence_of :body, :on => :create

  attr_accessor :body

  attr_readonly :posts_count, :hits

  extend FriendlyId
  friendly_id :title, use: [:slugged, :scoped], scope: :forum, slug_column: :permalink

  def to_s
    title
  end

  def sticky?
    sticky == 1
  end
  
  def hit!
    self.class.increment_counter :hits, id
  end

  def paged?
    posts_count > Post.per_page
  end

  def last_page
    [(posts_count.to_f / Post.per_page.to_f).ceil.to_i, 1].max
  end

  def post_number(post)
    self.posts.where("id <= #{post.id}").count
  end

  def post_page(post)
    [(post_number(post).to_f / Post.per_page.to_f).ceil.to_i, 1].max
  end

  def update_cached_post_fields(post)
    # these fields are not accessible to mass assignment
    if remaining_post = post.frozen? ? recent_post : post
      self.class.where(:id => id).update_all(:last_updated_at => remaining_post.created_at, :last_user_id => remaining_post.user_id, :last_post_id => remaining_post.id, :posts_count => posts.count)
    else
      destroy
    end
  end

  def to_param
    permalink
  end

  protected

    def create_initial_post
      user.reply self, @body # unless locked?
      @body = nil
    end

    def set_default_attributes
      self.site_id           = forum.site_id if forum_id
      self.sticky          ||= 0
      self.last_updated_at ||= Time.now.utc
    end

    def check_for_moved_forum
      old = Topic.find(id)
      @old_forum_id = old.forum_id if old.forum_id != forum_id
      true
    end

    def set_post_forum_id
      return unless @old_forum_id
      # Posts' forum_id needs a manual update_all (bypassing callbacks)
      # and a corresponding manual posts_count fix-up on both forums —
      # update_all on Post bypasses the `belongs_to :forum,
      # counter_cache: true` machinery. topics_count, on the other
      # hand, *is* handled by the counter_cache on this Topic's own
      # `belongs_to :forum`; don't double-count by adjusting it here.
      posts.update_all(:forum_id => forum_id)
      Forum.where(:id => @old_forum_id).update_all(["posts_count = posts_count - ?", posts_count])
      Forum.where(:id => forum_id).update_all(["posts_count = posts_count + ?", posts_count])
    end

    def count_user_posts_for_counter_cache
      @user_posts = posts.group_by { |p| p.user_id }
    end

    def update_cached_forum_and_user_counts
      # `posts_count` (the counter cache attribute) is stale on the
      # in-memory topic — the post counter is incremented via SQL
      # `UPDATE`, never refreshed on the object. By after_destroy time
      # the posts table has already cascade-deleted (dependent:
      # :delete_all), so `posts.count` returns 0 too. Use the snapshot
      # captured in `before_destroy`, which still reflects pre-destroy
      # reality.
      destroyed_post_count = @user_posts.values.sum(&:size)
      Forum.where(:id => forum_id).update_all(["posts_count = posts_count - ?", destroyed_post_count])
      Site.where(:id => site_id).update_all(["posts_count = posts_count - ?", destroyed_post_count])
      @user_posts.each do |user_id, posts|
        User.where(:id => user_id).update_all(["posts_count = posts_count - ?", posts.size])
      end
    end
end
