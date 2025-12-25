# frozen_string_literal: true

module Services
  module Areas
    class Update
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Areas::Update.call(params)
        unless validation.success?
          Rails.logger.warn "Area update validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        policy = ::Policies::AreaPolicy.new(current_account)
        return failure(["権限がありません"], :forbidden) unless policy.admin_only?

        value = validation.value
        update_attrs = value.except(:id).compact

        Area.transaction do
          area = @repository.find_by_id_with_lock(value[:id])
          return failure(["ID'#{value[:id]}'のエリアは存在しません"], :not_found) unless area

          unless @repository.update(area, update_attrs)
            Rails.logger.warn "Area update failed: id=#{area.id}, errors=#{area.errors.full_messages.join(', ')}"
            return failure(area.errors.full_messages, :unprocessable_entity)
          end

          Rails.logger.info "Area updated: id=#{area.id}, by_account=#{current_account.id}"
          Result.new(success?: true, area:, errors: [], status: :ok)
        end
      rescue ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked => e
        Rails.logger.error "Area update lock timeout: #{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再度お試しください"], :service_unavailable)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Area update DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, area: nil, errors:, status:)
        end
    end
  end
end
