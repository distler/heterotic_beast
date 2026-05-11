class Site < ApplicationRecord
  class UndefinedError < StandardError; end

  # NOTE: SQL-fragment where-clauses (not equality hashes) — equality
  # conditions in Rails 4 association scopes propagate as defaults on
  # `.build`/`.new`, which would override the AASM `:passive` initial state
  # and break the pending-then-activate signup flow.
  has_many :users,           -> { where("users.state = ?", "active") }
  has_many :all_users,       class_name: 'User'
  has_many :suspended_users, -> { where("users.state = ?", "suspended") }, class_name: 'User'
  has_many :pending_users,   -> { where("users.state = ?", "pending") },   class_name: 'User'

  has_many :forums,          -> { where("forums.state = ?", "public") }
  has_many :all_forums, :class_name => 'Forum'
  has_many :topics, :through => :forums
  has_many :posts,  :through => :forums

  validates_presence_of   :name
  validates_uniqueness_of :host

  attr_readonly :admin, :posts_count, :users_count, :topics_count, :users_online

  class << self

    def main
      @main ||= where(:host => '').first
    end

    def find_by_host(name)
      return nil if name.nil?
      # Each bang method returns nil when nothing changes, so chaining
      # them with `&&` (as the original code did) short-circuits and
      # skips later normalization. Apply each unconditionally.
      name = name.downcase.strip.sub(/^www\./, '')
      sites = where('host = ? or host = ?', name, '')
      sites.reject(&:default?).first || sites.first
    end

  end

  def users_online
      User.where("users.last_seen_at >= ? and users.site_id = ?", 10.minutes.ago.utc, id)
  end

  def admin
     User.where(:admin => true).first
  end

  def host=(value)
    write_attribute(:host, value.to_s.downcase)
  end

  # <3 rspec
  def ordered_forums(*args)
    forums.ordered_public.ordered(*args)
  end

  def default?
    host.blank?
  end

  def to_s
    name
  end
end
