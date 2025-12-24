# frozen_string_literal: true

module Contracts
  module Tasks
    # タスク更新の入力検証
    class Update
      include ActiveModel::Model

      attr_accessor :id, :task_title

      validates :id, presence: true
      validates :id, numericality: { only_integer: true, greater_than: 0 }, if: -> { id.present? }
      validate :task_title_must_be_scalar_string
      validates :task_title, length: { maximum: 256 }, allow_nil: true, if: -> { task_title.is_a?(String) }

      def self.call(params)
        contract = new(id: params[:id], task_title: params[:task_title])

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        attrs = { id: id.to_i }
        attrs[:task_title] = task_title if task_title.present?
        attrs
      end

      private
        # 配列などの非スカラー値を拒否（セキュリティ対策）
        def task_title_must_be_scalar_string
          return if task_title.nil?
          return if task_title.is_a?(String)

          errors.add(:task_title, "は文字列である必要があります")
        end
    end
  end
end
