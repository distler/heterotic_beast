class Forum < ApplicationRecord
  formats_attributes :description

  acts_as_list

  validates_presence_of :name

  belongs_to :site

  extend FriendlyId
  friendly_id :name, use: :slugged, slug_column: :permalink

  attr_readonly :posts_count, :topics_count

  has_many :topics, -> { order("#{Topic.table_name}.sticky desc, #{Topic.table_name}.last_updated_at desc") },
    dependent: :delete_all

  # this is used to see if a forum is "fresh"... we can't use topics because it puts
  # stickies first even if they are not the most recently modified
  has_many :recent_topics,
    -> { includes(:user).where('users.state = ?', 'active').order("#{Topic.table_name}.last_updated_at DESC") },
    class_name: 'Topic'
  has_one  :recent_topic,
    -> { order("#{Topic.table_name}.last_updated_at DESC") },
    class_name: 'Topic'

  has_many :posts,       -> { order("#{Post.table_name}.created_at DESC") }, dependent: :delete_all
  has_one  :recent_post, -> { order("#{Post.table_name}.created_at DESC") }, class_name: 'Post'

  has_many :moderatorships, dependent: :delete_all
  has_many :moderators, through: :moderatorships, source: :user

  scope :ordered_public, -> { where(state: 'public') }
  scope :ordered,        -> { order(:position) }

  def to_param
    permalink
  end

  def monitored_topics(user)
    self.topics.joins(:monitorships).where(:monitorships => {:user_id => user, :active => true})
  end

  def to_s
    name
  end
end
