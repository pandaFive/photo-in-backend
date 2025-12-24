# frozen_string_literal: true

module Services
  module Tasks
    class Show
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(nil, ["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Tasks::Show.call(params)
        return failure(nil, validation.errors, :unprocessable_entity) unless validation.success?

        # タスク取得
        task = @repository.find_by_id(validation.value[:id])
        return failure(nil, ["タスクが見つかりません"], :not_found) if task.nil?

        Result.new(success?: true, task:, tasks: nil, errors: [], status: :ok)
      end

      private
        def failure(task, errors, status)
          Result.new(success?: false, task:, tasks: nil, errors:, status:)
        end
    end
  end
end
