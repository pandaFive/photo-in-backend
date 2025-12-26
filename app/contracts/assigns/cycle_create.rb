# frozen_string_literal: true

module Contracts
  module Assigns
    # サイクル作成の入力検証
    # params: { assign_cycle: { task_id: Integer } } または { task_id: Integer }
    class CycleCreate
      include ActiveModel::Model

      attr_accessor :task_id

      validates :task_id, presence: { message: "タスクIDは必須です" }
      validates :task_id, numericality: { only_integer: true, greater_than: 0, message: "タスクIDは正の整数である必要があります" }, if: -> { task_id.present? }

      def self.call(params)
        # assign_cycle ネストに対応
        raw_task_id = params.dig(:assign_cycle, :task_id) || params[:task_id]
        contract = new(task_id: raw_task_id)

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        { task_id: task_id.to_i }
      end
    end
  end
end
