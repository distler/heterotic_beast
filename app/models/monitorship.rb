class Monitorship < ApplicationRecord
  belongs_to :user
  belongs_to :topic

  validates :user_id, :topic_id, :presence => true
  validate :uniqueness_of_relationship
  before_create :check_for_inactive

  protected

    def uniqueness_of_relationship
      if self.class.exists?(:user_id => user_id, :topic_id => topic_id, :active => true)
        errors.add(:base, "Cannot add duplicate user/topic relation")
      end
    end
  
    def check_for_inactive
      monitorship = self.class.find_by(user_id: user_id, topic_id: topic_id, active: false)
      if monitorship
        monitorship.active = true
        monitorship.save
        throw :abort
      end
    end
end