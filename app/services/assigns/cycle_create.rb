# frozen_string_literal: true

module Services
  module Assigns
    # サイクル作成サービス
    #
    # 認可: admin のみ
    # 同時更新防止: 悲観ロック
    class CycleCreate
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { assign_cycle: { task_id: Integer } } または { task_id: Integer }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        unless policy.admin_only?
          Rails.logger.warn "Cycle create unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"
          return failure(["権限がありません"], :forbidden)
        end

        # Contract検証
        validation = ::Contracts::Assigns::CycleCreate.call(params)
        unless validation.success?
          Rails.logger.warn "Cycle create validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        task_id = validation.value[:task_id]

        # トランザクション内で処理
        result = nil
        Task.transaction do
          # Task取得（悲観的ロック）
          task = @repository.find_task_with_lock(task_id)
          if task.nil?
            Rails.logger.warn "Task not found for cycle create: task_id=#{task_id}, by_account=#{current_account.id}"
            result = failure(["タスクが見つかりません"], :not_found)
            raise ActiveRecord::Rollback
          end

          # 既存サイクルを非アクティブ化
          deactivated_count = @repository.deactivate_all_cycles(task)
          Rails.logger.debug "Deactivated #{deactivated_count} cycles for task_id=#{task.id}"

          # 新サイクル作成
          cycle = @repository.create_cycle(task)

          # 割り当て実行
          assign_result = cycle.assign

          if assign_result
            Rails.logger.info "Cycle created: task_id=#{task.id}, cycle_id=#{cycle.id}, by_account=#{current_account.id}, assignee_id=#{assign_result.account_id}"
            result = success(cycle)
          else
            Rails.logger.warn "Cycle created but assignment failed: task_id=#{task.id}, cycle_id=#{cycle.id}, no_eligible_accounts=true"
            result = failure(["割り当て可能なメンバーがいません"], :unprocessable_entity)
            raise ActiveRecord::Rollback
          end
        end
        result
      rescue ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout => e
        Rails.logger.error "Cycle create lock error: task_id=#{params.dig(:assign_cycle, :task_id) || params[:task_id]}, error=#{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再度お試しください"], :service_unavailable)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Cycle create save error: task_id=#{params.dig(:assign_cycle, :task_id) || params[:task_id]}, error=#{e.message}"
        failure(["サイクル作成に失敗しました"], :unprocessable_entity)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Cycle create DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def success(cycle)
          Result.new(success?: true, cycle:, message: nil, errors: [], status: :created)
        end

        def failure(errors, status)
          Result.new(success?: false, cycle: nil, message: "failed", errors:, status:)
        end
    end
  end
end
