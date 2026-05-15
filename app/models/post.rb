class Post < ApplicationRecord
  include User::Editable

  formats_attributes :body

  # author of post
  belongs_to :user, :counter_cache => true

  belongs_to :topic, :counter_cache => true

  # topic's forum (set by callback)
  belongs_to :forum, :counter_cache => true

  # topic's site (set by callback)
  belongs_to :site, :counter_cache => true

  validates_presence_of :user_id, :site_id, :topic_id, :forum_id, :body
  # Only enforce on create — the intent is "can't add a NEW post to a
  # locked topic". On update, the topic was already lockable when the
  # post existed, and Rails revalidates persisted posts during autosave;
  # a post-create autosave would otherwise fail because the counter
  # cache has already ticked to >= 1.
  validate :topic_is_not_locked, on: :create

  after_create  :update_cached_fields
  after_update  :update_cached_fields
  after_destroy :update_cached_fields


  def self.search(query, options = {})
    scope = base_search_scope
    scope = scope.where("LOWER(#{Post.table_name}.body) LIKE ?", "%#{query}%") unless query.blank?
    scope.paginate(page: options[:page], per_page: options[:per_page])
  end

  def self.search_monitored(user_id, query, options = {})
    scope = base_search_scope.joins(
      "inner join #{Monitorship.table_name} as m on #{Post.table_name}.topic_id = m.topic_id AND " \
      "m.user_id = #{user_id.to_i} AND m.active != 0"
    )
    scope = scope.where("LOWER(#{Post.table_name}.body) LIKE ?", "%#{query}%") unless query.blank?
    scope.paginate(page: options[:page], per_page: options[:per_page])
  end

  def self.base_search_scope
    select("#{Post.table_name}.*, #{Topic.table_name}.title as topic_title, f.name as forum_name")
      .joins(
        "inner join #{Topic.table_name} on #{Post.table_name}.topic_id = #{Topic.table_name}.id " \
        "inner join #{Forum.table_name} as f on #{Topic.table_name}.forum_id = f.id"
      )
      .order("#{Post.table_name}.created_at DESC")
  end

  def forum_name
    forum.name
  end

  protected

    def update_cached_fields
      topic.update_cached_post_fields(self)
    end
  
    def topic_is_not_locked
      errors.add(:base, "Topic is locked") if topic && topic.locked? && topic.posts_count > 0
    end
end
