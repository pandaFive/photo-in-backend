# frozen_string_literal: true

module Services
  module Accounts
    # アカウント詳細取得ユースケース
    #
    # 管理者のみ実行可能
    class Show
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(nil, ["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Accounts::Show.call(params)
        unless validation.success?
          Rails.logger.warn "Account show validation failed: #{validation.errors.join(', ')}"
          return failure(nil, validation.errors, :unprocessable_entity)
        end

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(nil, ["権限がありません"], :forbidden) unless policy.admin_only?

        # アカウント取得
        value = validation.value
        account = @repository.get_account(value[:id])
        return failure(nil, ["ID'#{value[:id]}'のアカウントは存在しません"], :not_found) unless account

        Result.new(success?: true, account:, errors: [], status: :ok)
      end

      private
        def failure(account, errors, status)
          Result.new(success?: false, account:, errors:, status:)
        end
    end
  end
end
