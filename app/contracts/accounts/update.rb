# frozen_string_literal: true

module Contracts
  module Accounts
    class Update
      include ActiveModel::Model

      attr_accessor :id, :name, :password, :role, :capacity

      validates :id, presence: true
      validates :id, numericality: { only_integer: true, greater_than: 0 }, if: -> { id.present? }
      validates :name, length: { maximum: 32 }, allow_nil: true
      validates :password, length: { minimum: 8 }, allow_nil: true
      validates :role, inclusion: { in: %w[admin member] }, allow_nil: true
      validates :capacity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

      def self.call(params)
        contract = new(
          id: params[:id],
          name: params[:name],
          password: params[:password],
          role: params[:role],
          capacity: params[:capacity]
        )

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        {
          id:,
          name:,
          password:,
          role:,
          capacity: capacity.present? ? capacity.to_i : nil
        }
      end
    end
  end
end
