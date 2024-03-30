class AssignCycle < ApplicationRecord
  belongs_to :task

  has_many :assign_history

  def assign
    accounts = get_assignable

    target = accounts.first

    current_assign = Assign_historie.new(account_id: target.id, assign_cycle_id: self.id)

    if current_assign.save
      true
    else
      false
    end
  end

  def get_assignable
    task = self.try(:task)

    accounts = Account.joins(:areas)
                  .includes(:assign_histories)
                  .where(areas: { name: task.area.name })
                  .where.not(assign_histories: { assign_cycle_id: self.id })
                  .where(assign_histories: { ng: false })
                  .where(assign_histories: { completed: false })
                  .group(:id)
                  .select("accounts.*, COUNT(assign_histories.id) AS assing_count")
                  .having("assign_count < accounts.capacity * 4")
  end

  def completed
    self.deactivation
    target = AssignHistory.joins(:assign_cycles)
                .where(assign_cycles: { id: self.id })
                .where(ng: false)
    target.completed
  end

  def deactivation
    self.is_active = false
  end

  class << self
    def unfulfilleds
      targets = AssignCycle.where(is_active: true)
    end
  end
end
