# frozen_string_literal: true

module Services
  module Areas
    class Destroy
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Areas::Destroy.call(params)
        unless validation.success?
          Rails.logger.warn "Area destroy validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        policy = ::Policies::AreaPolicy.new(current_account)
        unless policy.admin_only?
          Rails.logger.warn "Area destroy unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"
          return failure(["権限がありません"], :forbidden)
        end

        area = @repository.find_by_id(validation.value[:id])
        return failure(["ID'#{validation.value[:id]}'のエリアは存在しません"], :not_found) unless area

        unless @repository.destroy(area)
          Rails.logger.error "Area destroy failed (callbacks): id=#{area.id}, errors=#{area.errors.full_messages.join(', ')}"
          return failure(["エリアの削除に失敗しました"], :unprocessable_entity)
        end

        Rails.logger.info "Area destroyed: id=#{validation.value[:id]}, by_account=#{current_account.id}"
        Result.new(success?: true, message: "deleted", errors: [], status: :ok)
      rescue ActiveRecord::InvalidForeignKey => e
        Rails.logger.error "Area destroy failed (FK constraint): id=#{area.id}, error=#{e.message}"
        failure(["このエリアにはアカウントが関連付けられているため削除できません"], :conflict)
      rescue ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked => e
        Rails.logger.error "Area destroy lock timeout: #{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再度お試しください"], :service_unavailable)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Area destroy DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, message: nil, errors:, status:)
        end
    end
  end
end
