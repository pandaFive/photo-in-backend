module Contracts
  module Accounts
    class Show
      include ActiveModel::Model

      attr_accessor :id

      validates :id, presence: true, numericality: { only_integer: true }

      def self.call(params)
        contract = new(
          id: params[:id]
        )

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        {
          id:
        }
      end
    end
  end
end
