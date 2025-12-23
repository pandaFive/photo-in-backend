module Contracts
  module Authentications
    class Login
      include ActiveModel::Model

      attr_accessor :name, :password

      validates :name, presence: true
      # bcryptは72バイトまでしか処理しないため、DoS攻撃対策として上限を設定
      validates :password, presence: true, length: { maximum: 72 }

      def self.call(params)
        contract = new(
          name: params[:name],
          password: params[:password]
        )

        if contract.valid?
          Contracts::Result.new(success?: true, value: contract, errors: [])
        else
          Contracts::Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end
    end
  end
end
