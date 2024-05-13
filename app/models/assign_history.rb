class AssignHistory < ApplicationRecord
  belongs_to :account
  belongs_to :assign_cycle

  def change_completed
    ActiveRecord::Base.transaction do
      self.update(completed: true, completed_at: Time.current)
      cycle = AssignCycle.find(self.assign_cycle_id)
      cycle.deactivation
    end
  end

  def completed_test
    today = Date.today
    self.update(completed: true, completed_at: today - rand(1..7))
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
