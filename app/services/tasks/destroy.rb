# frozen_string_literal: true

module Services
  module Tasks
    class Destroy
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Tasks::Destroy.call(params)
        return failure(validation.errors, :unprocessable_entity) unless validation.success?

        # 認可チェック（管理者のみ）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(["権限がありません"], :forbidden) unless policy.admin_only?

        # トランザクション内で削除を実行
        Task.transaction do
          # タスク取得
          task = @repository.find_by_id(validation.value[:id])
          return failure(["タスクが見つかりません"], :not_found) if task.nil?

          # 削除実行
          deleted = @repository.delete(task)
          unless deleted
            Rails.logger.warn "Task destroy callback blocked: id=#{task.id}, account=#{current_account.id}"
            return failure(["タスクの削除に失敗しました"], :unprocessable_entity)
          end

          Rails.logger.info "Task destroyed: id=#{task.id}, title=#{task.task_title}, by_account=#{current_account.id}"
          success
        end
      rescue ActiveRecord::InvalidForeignKey => e
        Rails.logger.error "Task destroy FK violation: id=#{validation.value[:id]}, account=#{current_account.id}, error=#{e.message}"
        failure(["関連データが存在するため削除できません"], :conflict)
      end

      private
        def success
          DestroyResult.new(success?: true, message: "deleted", errors: [], status: :ok)
        end

        def failure(errors, status)
          DestroyResult.new(success?: false, message: nil, errors:, status:)
        end
    end

    # Destroy専用Result（taskを返さない）
    DestroyResult = Struct.new(:success?, :message, :errors, :status, keyword_init: true)
  end
end
