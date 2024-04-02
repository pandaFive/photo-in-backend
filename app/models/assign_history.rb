class AssignHistory < ApplicationRecord
  belongs_to :account
  belongs_to :assign_cycle

  def completed
    self.completed = true
    self.completed_at = Time.current
  end

  class << self
    def get_completed_past_week
      completed_count = AssignHistory.where("completed_at > ?", 1.week.ago)
                            .group_by { |assign_histories| assign_histories.completed_at.to_date }
                            .transform_values(&:count)
      completed_count
    end
  end
end
