# frozen_string_literal: true

module Services
  module Tasks
    # タスク完了処理
    class Completed
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Tasks::Completed.call(params)
        return failure(validation.errors, :unprocessable_entity) unless validation.success?

        # トランザクション内で処理
        AssignHistory.transaction do
          # AssignHistory取得（悲観的ロック）
          assign_history = @repository.find_assign_history_with_lock(validation.value[:id])
          return failure(["担当履歴が見つかりません"], :not_found) if assign_history.nil?

          # 関連するTaskを取得
          task = assign_history.assign_cycle.task

          # 認可チェック（管理者 または 現在のアクティブな担当者のみ）
          unless can_complete?(current_account, task)
            return failure(["権限がありません"], :forbidden)
          end

          # 既に完了済みチェック
          if assign_history.completed?
            return failure(["既に完了しています"], :unprocessable_entity)
          end

          # 完了処理実行: AssignHistory完了 + AssignCycle非アクティブ化（トランザクション内で実行）
          @repository.complete_assign_history(assign_history)
          @repository.deactivate_cycle(assign_history.assign_cycle)

          Rails.logger.info "Task completed: assign_history_id=#{assign_history.id}, task_id=#{task.id}, by_account=#{current_account.id}"
          success
        end
      rescue ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout => e
        Rails.logger.error "Task complete lock error: id=#{params[:id]}, error=#{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再試行してください。"], :service_unavailable)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Task complete save error: id=#{params[:id]}, error=#{e.message}"
        failure(["タスクの完了処理に失敗しました。"], :unprocessable_entity)
      end

      private
        def can_complete?(account, task)
          policy = ::Policies::AccountPolicy.new(account)
          return true if policy.admin_only?

          task.current_assignee?(account)
        end

        def success
          Result.new(success?: true, message: "change completed", errors: [], status: :ok)
        end

        def failure(errors, status)
          Result.new(success?: false, message: "change failed", errors:, status:)
        end
    end
  end
end
