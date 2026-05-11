class User < ApplicationRecord
  # bcrypt-backed `password=` / `password_confirmation=` / `#authenticate`
  # via the `password_digest` column. `validations: false` lets us keep
  # our existing `password_required?`-gated validators in User::Validation
  # (which handle OpenID-only signups and the post-bcrypt-cutover
  # `password_digest IS NULL` rows).
  has_secure_password validations: false

  include User::States
  include User::Activation
  include User::Posting
  include User::Validation

  formats_attributes :bio

  belongs_to :site, :counter_cache => true
  validates_presence_of :site_id

  has_many :posts,  -> { order("#{Post.table_name}.created_at desc") },  dependent: :delete_all
  has_many :topics, -> { order("#{Topic.table_name}.created_at desc") }, dependent: :delete_all

  has_many :moderatorships, :dependent => :delete_all
  has_many :forums, :through => :moderatorships, :source => :forum do
    def moderatable
      select("#{Forum.table_name}.*, #{Moderatorship.table_name}.id as moderatorship_id")
    end
  end

  has_many :monitorships, :dependent => :delete_all
  has_many :monitored_topics, -> { where("#{Monitorship.table_name}.active" => true) }, through: :monitorships, source: :topic

  extend FriendlyId
  friendly_id :login, use: [:slugged, :scoped], scope: :site, slug_column: :permalink

  attr_readonly :posts_count, :last_seen_at

  scope :named_like, ->(name) { where('users.display_name like ? or users.login like ?', "#{name}%", "#{name}%") }
  scope :online,     -> { where('users.last_seen_at >= ?', 10.minutes.ago.utc) }

  class << self

    def prefetch_from(records)
      select("distinct *").where(:id => records.collect(&:user_id).uniq)
    end

    def index_from(records)
      prefetch_from(records).index_by(&:id)
    end

  end

  def available_forums
    @available_forums ||= site.ordered_forums - forums
  end

  def moderator_of?(forum)
    !!(admin? || Moderatorship.exists?(:user_id => id, :forum_id => forum.id))
  end

  def display_name
    n = read_attribute(:display_name)
    n.blank? ? login : n
  end

  alias_method :to_s, :display_name

  # this is used to keep track of the last time a user has been seen (reading a topic)
  # it is used to know when topics are new or old and which should have the green
  # activity light next to them
  #
  # we cheat by not calling it all the time, but rather only when a user views a topic
  # which means it isn't truly "last seen at" but it does serve it's intended purpose
  #
  # This is now also used to show which users are online... not at accurate as the
  # session based approach, but less code and less overhead.
  def seen!
    now = Time.now.utc
    self.class.where(:id => id).update_all(:last_seen_at => now)
    write_attribute(:last_seen_at, now)
  end

  def to_param
    id.to_s # permalink || login
  end

  def openid_url=(value)
    write_attribute :openid_url, value.blank? ? nil : OpenID.normalize_url(value)
  end

  def using_openid
    self.openid_url.blank? ? false : true
  end

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] += [:email, :login_key, :login_key_expires_at, :password_hash, :openid_url, :activated, :admin]
    super
  end
end
