# frozen_string_literal: true

module Contracts
  module Tasks
    # タスクからのタグ削除の入力検証
    class RemoveTag
      include ActiveModel::Model

      attr_accessor :task_id, :tag_id

      validates :task_id, presence: true
      validates :task_id, numericality: { only_integer: true, greater_than: 0 }, if: -> { task_id.present? }
      validates :tag_id, presence: true
      validates :tag_id, numericality: { only_integer: true, greater_than: 0 }, if: -> { tag_id.present? }

      def self.call(params)
        # ルート互換性: :id も :task_id として扱う
        task_id_value = params[:task_id] || params[:id]
        contract = new(task_id: task_id_value, tag_id: params[:tag_id])

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        { task_id: task_id.to_i, tag_id: tag_id.to_i }
      end
    end
  end
end
