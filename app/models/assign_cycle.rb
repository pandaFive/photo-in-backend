class AssignCycle < ApplicationRecord
  belongs_to :task

  has_many :assign_history

  def assign
    accounts = get_assignable

    target = accounts.first

    current_assign = Assign_historie.new(account_id: target.id, assign_cycle_id: self.id)

    if current_assign.save
      current_assign
    else
      current_assign.errors
    end
  end

  def get_assignable
    task = self.try(:task)

    accounts = Account.joins(:areas)
                  .includes(:ng_histories)
                  .where(areas: { name: task.area.name })
                  .where.not(ng_histories: { assign_cycle_id: self.id })
                  .left_joins(:assign_histories, :ng_histories, :is_completeds)
                  .where(assign_histories: { id: nil })
                  .where(ng_histories: { id: nil })
                  .where(is_completeds: { id: nil })
                  .group(:id)
                  .select("accounts.*, COUNT(assign_histories.id) AS assign_count")
                  .having("assign_count < accounts.capacity * 4")
  end
end
