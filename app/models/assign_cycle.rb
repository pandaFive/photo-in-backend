# frozen_string_literal: true

class AssignCycle < ApplicationRecord
  belongs_to :task

  has_many :assign_histories
  has_many :comments

  # 割り当て可能なアカウントに割り当てを実行
  # @return [AssignHistory] 割り当て成功時
  # @return [false] 割り当て可能なアカウントがない場合
  # @raise [ActiveRecord::RecordInvalid] AssignHistory の保存に失敗した場合
  def assign
    accounts = ::Services::AssignableAccountsService.new(assign_cycle: self).call
    target = accounts.first

    return false if target.nil?

    current_assign = AssignHistory.new(account_id: target.id, assign_cycle_id: id)
    current_assign.save!
    current_assign
  end

  def get_assignable
    ::Services::AssignableAccountsService.new(assign_cycle: self).call
  end

  def completed
    deactivation
    target = AssignHistory.joins(:assign_cycle)
                .where(assign_cycles: { id: })
                .where(ng: false)
    target.completed
  end

  def deactivation
    update(is_active: false)
  end

  # アクティブな割り当てサイクルを取得
  scope :unfulfilleds, -> { where(is_active: true) }
end
