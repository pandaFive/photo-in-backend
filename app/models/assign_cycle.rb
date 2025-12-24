# frozen_string_literal: true

class AssignCycle < ApplicationRecord
  belongs_to :task

  has_many :assign_histories
  has_many :comments

  def assign
    accounts = ::Services::AssignableAccountsService.new(assign_cycle: self).call
    target = accounts.first

    return false if target.nil?

    current_assign = AssignHistory.new(account_id: target.id, assign_cycle_id: id)
    current_assign.save ? current_assign : false
  end

  def get_assignable
    ::Services::AssignableAccountsService.new(assign_cycle: self).call
  end

  def completed
    self.deactivation
    target = AssignHistory.joins(:assign_cycle)
                .where(assign_cycles: { id: self.id })
                .where(ng: false)
    target.completed
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
