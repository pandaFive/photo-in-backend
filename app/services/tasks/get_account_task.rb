# frozen_string_literal: true

module Services
  module Tasks
    # アカウント割り当てタスク取得
    # 認可: 管理者は全アカウント、一般メンバーは自分のみ
    class GetAccountTask
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        contract_result = Contracts::Tasks::GetAccountTask.call(params)
        return failure(contract_result.errors, :unprocessable_entity) unless contract_result.success?

        account_id = contract_result.value[:account_id]

        policy = ::Policies::AccountPolicy.new(current_account)
        unless authorized?(policy, current_account, account_id)
          return failure(["この操作を行う権限がありません"], :forbidden)
        end

        tasks = @repository.get_account_assign_tasks(account_id)
        success(tasks)
      rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
        log_error("データベース接続失敗", e, current_account)
        failure(["データベース接続に失敗しました。しばらくしてから再試行してください。"], :service_unavailable)
      rescue ActiveRecord::StatementInvalid, ActiveRecord::QueryCanceled => e
        log_error("データベースクエリ失敗", e, current_account)
        failure(["データの取得に失敗しました。"], :internal_server_error)
      end

      private
        # 認可判定: 管理者か自分自身へのアクセスのみ許可
        def authorized?(policy, current_account, target_account_id)
          policy.admin_only? || current_account.id == target_account_id
        end

        def success(tasks)
          Result.new(success?: true, task: nil, tasks:, errors: [], status: :ok)
        end

        def failure(errors, status)
          Result.new(success?: false, task: nil, tasks: nil, errors:, status:)
        end

        def log_error(message, error, account)
          Rails.logger.error(
            message:,
            error_class: error.class.name,
            error_message: error.message,
            account_id: account&.id,
            backtrace: error.backtrace&.first(10)&.join("\n")
          )
        end
    end
  end
end
