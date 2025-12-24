# frozen_string_literal: true

module Contracts
  module Accounts
    class Create
      include ActiveModel::Model

      attr_accessor :name, :password, :role, :capacity, :area

      validates :name, presence: true, length: { maximum: 32 }
      validates :password, presence: true, length: { minimum: 8 }
      validates :role, presence: true, inclusion: { in: %w[admin member] }
      validates :capacity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

      validates_with Validators::Accounts::Create

      def self.call(params)
        contract = new(
          name: params[:name],
          password: params[:password],
          role: params[:role],
          capacity: params[:capacity],
          area: params[:area]
        )

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        {
          name:,
          password:,
          role:,
          capacity: capacity.present? ? capacity.to_i : nil,
          area_ids:
        }
      end

      private
        def area_ids
          @area_ids ||= Array(area).compact.map(&:to_i)
        end
    end
  end
end
