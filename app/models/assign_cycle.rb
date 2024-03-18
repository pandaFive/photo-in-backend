class AssignCycle < ApplicationRecord
  belongs_to :task

  has_many :assign_history
end
