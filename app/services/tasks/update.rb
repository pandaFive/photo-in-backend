# frozen_string_literal: true

module Services
  module Tasks
    class Update
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(nil, ["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Tasks::Update.call(params)
        return failure(nil, validation.errors, :unprocessable_entity) unless validation.success?

        update_attrs = validation.value.except(:id)

        # トランザクション内で認可チェックと更新を実行（レースコンディション防止）
        Task.transaction do
          # タスク取得（悲観的ロック）
          task = @repository.find_by_id_with_lock(validation.value[:id])
          return failure(nil, ["タスクが見つかりません"], :not_found) if task.nil?

          # 認可チェック（管理者 または タスク担当者）
          unless can_update?(current_account, task)
            return failure(nil, ["権限がありません"], :forbidden)
          end

          # 更新実行
          return success(task) if update_attrs.empty?

          unless @repository.update(task, update_attrs)
            return failure(task, task.errors.full_messages, :unprocessable_entity)
          end

          success(task)
        end
      end

      private
        def can_update?(account, task)
          policy = ::Policies::AccountPolicy.new(account)
          return true if policy.admin_only?

          task.current_assignee?(account)
        end

        def success(task)
          Result.new(success?: true, task:, tasks: nil, errors: [], status: :ok)
        end

        def failure(task, errors, status)
          Result.new(success?: false, task:, tasks: nil, errors:, status:)
        end
    end
  end
end
