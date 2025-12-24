# frozen_string_literal: true

module Services
  module Authentications
    class Login
      def call(params)
        # バリデーション
        validation = ::Contracts::Authentications::Login.call(params)
        return failure(validation.errors, :unprocessable_entity) unless validation.success?

        # アカウント検索と認証（タイミング攻撃対策のため常にbcrypt処理を実行）
        account = Account.find_by(name: validation.value.name)
        authenticated = perform_authentication(account, validation.value.password)

        unless authenticated
          # 監査ログ: 認証失敗を記録（ユーザー名は記録するがパスワードは記録しない）
          Rails.logger.warn "[AUTH] Login failed for user: #{validation.value.name}"
          return failure(["認証に失敗しました"], :unprocessable_entity)
        end

        Rails.logger.info "[AUTH] Login successful for user: #{account.name} (ID: #{account.id})"
        Result.new(success?: true, account:, errors: [], status: :ok)
      end

      private
        # タイミング攻撃対策：アカウント存在有無に関わらず常にbcrypt処理を実行
        def perform_authentication(account, password)
          if account
            account.authenticate(password)
          else
            # アカウントが存在しない場合もbcrypt処理を実行して応答時間を統一
            dummy_hash = "$2a$12$K0ByB.6YI2/OO0HMprYi4.SqKMiqcj9E.aMKgFWmoOo.Ij0bNfILK"
            BCrypt::Password.new(dummy_hash) == password
            false
          end
        end

        def failure(errors, status)
          Result.new(success?: false, account: nil, errors:, status:)
        end
    end
  end
end
