# frozen_string_literal: true

module Contracts
  module Areas
    class Create
      include ActiveModel::Model

      attr_accessor :name

      validates :name, presence: true, length: { maximum: 32 }

      def self.call(params)
        contract = new(name: params.dig(:area, :name) || params[:name])

        if contract.valid?
          Result.new(success?: true, value: { name: contract.name }, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end
    end
  end
end
