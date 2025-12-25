# frozen_string_literal: true

module Contracts
  module Areas
    class IdContract
      include ActiveModel::Model

      attr_accessor :id

      validates :id, presence: true
      validates :id, numericality: { only_integer: true, greater_than: 0 }, if: -> { id.present? }

      def self.call(params)
        contract = new(id: params[:id])

        if contract.valid?
          Contracts::Result.new(success?: true, value: { id: contract.id.to_i }, errors: [])
        else
          Contracts::Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end
    end
  end
end
