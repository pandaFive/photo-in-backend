# frozen_string_literal: true

module Contracts
  module Areas
    class Update
      include ActiveModel::Model

      attr_accessor :id, :name

      validates :id, presence: true
      validates :id, numericality: { only_integer: true, greater_than: 0 }, if: -> { id.present? }
      validates :name, length: { maximum: 32 }, allow_nil: true

      def self.call(params)
        contract = new(
          id: params[:id],
          name: params.dig(:area, :name) || params[:name]
        )

        if contract.valid?
          Contracts::Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Contracts::Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        { id: id.to_i, name: }.compact
      end
    end
  end
end
