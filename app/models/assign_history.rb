class AssignHistory < ApplicationRecord
  belongs_to :account
  belongs_to :assign_cycle

  def completed
    self.completed = true
    self.completed_at = Time.current
  end
end
