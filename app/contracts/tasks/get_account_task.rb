# frozen_string_literal: true

module Contracts
  module Tasks
    # アカウント割り当てタスク取得の入力検証
    class GetAccountTask
      include ActiveModel::Model

      attr_accessor :account_id

      validates :account_id, presence: true
      validates :account_id, numericality: { only_integer: true, greater_than: 0 }, if: -> { account_id.present? }

      def self.call(params)
        contract = new(account_id: params[:id])

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        { account_id: account_id.to_i }
      end
    end
  end
end
