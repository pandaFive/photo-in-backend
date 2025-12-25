# frozen_string_literal: true

module Services
  module Accounts
    # アカウント削除ユースケース
    #
    # 管理者のみ実行可能
    class Destroy
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Accounts::Destroy.call(params)
        return failure(validation.errors, :unprocessable_entity) unless validation.success?

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(["権限がありません"], :forbidden) unless policy.admin_only?

        # アカウント取得
        value = validation.value
        account = @repository.get_account(value[:id])
        return failure(["ID'#{value[:id]}'のアカウントは存在しません"], :not_found) unless account

        # 削除実行
        unless @repository.destroy(account)
          return failure(account.errors.full_messages, :unprocessable_entity)
        end

        Result.new(success?: true, message: "deleted", errors: [], status: :ok)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, message: nil, errors:, status:)
        end
    end
  end
end
