module Services
  module Tasks
    class Index
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(nil, ["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Tasks::Index.call(params)
        return failure(nil, validation.errors, :unprocessable_entity) unless validation.success?

        # タスク一覧取得
        type = validation.value[:type]
        tasks = type == "all" ? @repository.list_active_tasks : @repository.list_ng_tasks

        Result.new(success?: true, task: nil, tasks:, errors: [], status: :ok)
      end

      private
        def failure(task, errors, status)
          Result.new(success?: false, task:, tasks: nil, errors:, status:)
        end
    end
  end
end
