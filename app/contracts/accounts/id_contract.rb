# frozen_string_literal: true

module Contracts
  module Accounts
    # ID検証用の基底Contract
    #
    # Show, Destroy など ID のみを検証するContractの共通基盤
    class IdContract
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
        { id: }
      end
    end
  end
end
