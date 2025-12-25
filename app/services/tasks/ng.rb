# frozen_string_literal: true

module Services
  module Tasks
    # タスクNG（辞退）処理
    class Ng
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Tasks::Ng.call(params)
        return failure(validation.errors, :unprocessable_entity) unless validation.success?

        # トランザクション内で処理
        AssignHistory.transaction do
          # AssignHistory取得（悲観的ロック）
          assign_history = @repository.find_assign_history_with_lock(validation.value[:id])
          return failure(["担当履歴が見つかりません"], :not_found) if assign_history.nil?

          # 関連するTaskを取得
          task = assign_history.assign_cycle.task

          # 認可チェック（管理者 または 現在のアクティブな担当者のみ）
          unless can_mark_ng?(current_account, task)
            return failure(["権限がありません"], :forbidden)
          end

          # 既にNG済みチェック
          if assign_history.ng?
            return failure(["既にNGです"], :unprocessable_entity)
          end

          # 既に完了済みチェック
          if assign_history.completed?
            return failure(["既に完了しています"], :unprocessable_entity)
          end

          # NG処理実行
          @repository.mark_ng(assign_history)

          # 再割り当て実行
          cycle = assign_history.assign_cycle
          reassign_result = cycle.assign

          if reassign_result
            Rails.logger.info "Task NG: assign_history_id=#{assign_history.id}, task_id=#{task.id}, by_account=#{current_account.id}, reassigned=true, new_assignee_id=#{reassign_result.account_id}"
            success("complete")
          else
            # 再割り当て失敗: 適格者なし または 保存失敗
            Rails.logger.warn "Task NG reassignment failed: assign_history_id=#{assign_history.id}, task_id=#{task.id}, cycle_id=#{cycle.id}, no_eligible_accounts_or_save_failed=true"
            success("failed") # NGは成功、再割り当てのみ失敗
          end
        end
      rescue ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout => e
        Rails.logger.error "Task NG lock error: id=#{params[:id]}, error=#{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再試行してください。"], :service_unavailable)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Task NG save error: id=#{params[:id]}, error=#{e.message}"
        failure(["NG処理に失敗しました。"], :unprocessable_entity)
      end

      private
        def can_mark_ng?(account, task)
          policy = ::Policies::AccountPolicy.new(account)
          return true if policy.admin_only?

          task.current_assignee?(account)
        end

        def success(message)
          Result.new(success?: true, message:, errors: [], status: :ok)
        end

        def failure(errors, status)
          Result.new(success?: false, message: "failed", errors:, status:)
        end
    end
  end
end
