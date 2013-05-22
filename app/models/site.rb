class Site < ActiveRecord::Base
  class UndefinedError < StandardError; end

  has_many :users, :conditions => {:state => 'active'}
  has_many :all_users, :class_name => 'User'
  has_many :suspended_users, :class_name => 'User', :conditions => {:state => 'suspended'}
  has_many :pending_users,   :class_name => 'User', :conditions => {:state => 'pending'}

  has_many :forums, :conditions => {:state => 'public'}
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
      name.downcase! && name.strip! && name.sub!(/^www\./, '')
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
    forums.ordered(*args)
  end

  def default?
    host.blank?
  end

  def to_s
    name
  end
end
