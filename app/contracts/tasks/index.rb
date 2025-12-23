module Contracts
  module Tasks
    class Index
      include ActiveModel::Model

      attr_accessor :type

      validates :type, presence: true, inclusion: { in: %w[all ng] }

      def self.call(params)
        contract = new(type: params[:type])

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        { type: }
      end
    end
  end
end
