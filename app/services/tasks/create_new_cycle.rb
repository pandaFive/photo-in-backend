# frozen_string_literal: true

module Services
  module Tasks
    # 新サイクル作成処理（タスクの再起動）
    class CreateNewCycle
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], nil, :unauthorized) if current_account.nil?

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(["権限がありません"], nil, :forbidden) unless policy.admin_only?

        # Contract検証
        validation = ::Contracts::Tasks::CreateNewCycle.call(params)
        return failure(validation.errors, nil, :unprocessable_entity) unless validation.success?

        # トランザクション内で処理
        result = nil
        Task.transaction do
          # Task取得（悲観的ロック）
          task = @repository.find_by_id_with_lock(validation.value[:id])
          if task.nil?
            result = failure(["タスクが見つかりません"], nil, :not_found)
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
            Rails.logger.info "New cycle created: task_id=#{task.id}, cycle_id=#{cycle.id}, by_account=#{current_account.id}, assignee_id=#{assign_result.account_id}"
            result = success(task)
          else
            Rails.logger.warn "New cycle created but assignment failed: task_id=#{task.id}, cycle_id=#{cycle.id}, no_eligible_accounts=true"
            result = failure(["割り当て可能なメンバーがいません"], nil, :unprocessable_entity)
            raise ActiveRecord::Rollback
          end
        end
        result
      rescue ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout => e
        Rails.logger.error "CreateNewCycle lock error: id=#{params[:id]}, error=#{e.message}"
        failure(["サーバーが混雑しています"], nil, :service_unavailable)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "CreateNewCycle save error: id=#{params[:id]}, error=#{e.message}"
        failure(["サイクル作成に失敗しました"], nil, :unprocessable_entity)
      end

      private
        def success(task)
          CreateNewCycleResult.new(success?: true, task:, message: nil, errors: [], status: :ok)
        end

        def failure(errors, task, status)
          CreateNewCycleResult.new(success?: false, task:, message: "failed", errors:, status:)
        end
    end

    # CreateNewCycle専用Result
    CreateNewCycleResult = Struct.new(:success?, :task, :message, :errors, :status, keyword_init: true)
  end
end
