# frozen_string_literal: true

module Contracts
  module Tasks
    # タスク更新の入力検証
    class Update
      include ActiveModel::Model

      attr_accessor :id, :task_title

      validates :id, presence: true
      validates :id, numericality: { only_integer: true, greater_than: 0 }, if: -> { id.present? }
      validates :task_title, length: { maximum: 256 }, allow_nil: true

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
    end
  end
end
