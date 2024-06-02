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
      current_assign
    else
      false
    end
  end

  def get_assignable
    task = self.try(:task)

    assigned = Account.left_joins(assign_histories: :assign_cycle)
                  .where(assign_cycles: { id: self.id })

    over_cap = Account.joins(:areas)
                  .left_outer_joins(assign_histories: :assign_cycle)
                  .group("accounts.id")
                  .where(areas: { id: task.area.id })
                  .where("assign_histories.ng = false OR assign_histories.ng IS NULL")
                  .where("assign_histories.completed = false OR assign_histories.completed IS NULL")
                  .having("COUNT(assign_histories.id) >= accounts.capacity * 4")

    accounts = Account.joins(:areas)
                  .where(areas: { id: task.area.id })
                  .where.not(id: assigned.select(:id))
                  .where.not(id: over_cap.select(:id))

    accounts
  end

  def completed
    self.deactivation
    target = AssignHistory.joins(:assign_cycle)
                .where(assign_cycles: { id: self.id })
                .where(ng: false)
    target.completed
  end

  def completed_test
    self.deactivation
    target = AssignHistory.joins(:assign_cycle)
                .where(assign_cycles: { id: self.id })
                .where(ng: false)
    if target
      history = AssignHistory.find(target.ids[0])
      history.completed_test
    end

    target
  end

  def deactivation
    self.update(is_active: false)
  end

  class << self
    def unfulfilleds
      targets = AssignCycle.where(is_active: true)
      targets
    end
  end
end
