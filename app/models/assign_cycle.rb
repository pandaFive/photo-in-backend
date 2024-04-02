class AssignCycle < ApplicationRecord
  belongs_to :task

  has_many :assign_histories

  def assign
    accounts = get_assignable

    target = accounts.first

    if target == nil
      return false
    end

    current_assign = AssignHistory.new(account_id: target.id, assign_cycle_id: self.id)

    if current_assign.save
      true
    else
      false
    end
  end

  def get_assignable
    task = self.try(:task)

    assigned = Account.left_joins(assign_histories: :assign_cycle)
                  .where(assign_cycles: { id: self.id })

    accounts = Account.joins(:areas)
                  .left_outer_joins(assign_histories: :assign_cycle)
                  .group("accounts.id")
                  .where(areas: { id: task.area.id })
                  .where("assign_histories.ng = false OR assign_histories.ng IS NULL")
                  .where("assign_histories.completed = false OR assign_histories.completed IS NULL")
                  .having("COUNT(assign_histories.id) < accounts.capacity * 4")
                  .where.not(id: assigned.select(:id))

    accounts
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
      targets
    end
  end
end
