module Services
  module Authentications
    class Login
      Result = Struct.new(:success?, :account, :errors, :status, keyword_init: true)

      def call(params)
        # バリデーション
        validation = ::Contracts::Authentications::Login.call(params)
        return failure(validation.errors, :unprocessable_entity) unless validation.success?

        # アカウント検索
        account = Account.find_by(name: validation.value.name)
        return failure(["認証に失敗しました"], :unprocessable_entity) unless account

        # パスワード認証
        unless account.authenticate(validation.value.password)
          return failure(["認証に失敗しました"], :unprocessable_entity)
        end

        Result.new(success?: true, account:, errors: [], status: :ok)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, account: nil, errors:, status:)
        end
    end
  end
end
