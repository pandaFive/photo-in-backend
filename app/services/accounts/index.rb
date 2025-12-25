# frozen_string_literal: true

module Services
  module Accounts
    # メンバー一覧取得ユースケース
    #
    # 管理者のみ実行可能。統計情報（完了数、NG率等）も含む
    class Index
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(["権限がありません"], :forbidden) unless policy.admin_only?

        # データ取得
        accounts = @repository.list_members
        data = @repository.get_accounts_stats(accounts)
        Result.new(success?: true, accounts:, data:, errors: [], status: :ok)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, accounts: [], errors:, status:)
        end
    end
  end
end
