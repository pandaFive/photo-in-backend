module Contracts
  module Authentications
    class Login
      include ActiveModel::Model

      attr_accessor :name, :password

      validates :name, presence: true
      validates :password, presence: true

      def self.call(params)
        contract = new(
          name: params[:name],
          password: params[:password]
        )

        if contract.valid?
          Result.new(success?: true, value: contract, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      Result = Struct.new(:success?, :value, :errors, keyword_init: true)
    end
  end
end
