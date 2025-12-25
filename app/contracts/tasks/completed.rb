# frozen_string_literal: true

module Contracts
  module Tasks
    # タスク完了の入力検証
    # Note: idはAssignHistoryのID（APIパス /tasks/:id/completed の :id は歴史的経緯による命名）
    class Completed
      include ActiveModel::Model

      attr_accessor :id

      validates :id, presence: true
      validates :id, numericality: { only_integer: true, greater_than: 0 }, if: -> { id.present? }

      def self.call(params)
        contract = new(id: params[:id])

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        { id: id.to_i }
      end
    end
  end
end
