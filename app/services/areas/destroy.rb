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
        return failure(["権限がありません"], :forbidden) unless policy.admin_only?

        area = @repository.find_by_id(validation.value[:id])
        return failure(["ID'#{validation.value[:id]}'のエリアは存在しません"], :not_found) unless area

        begin
          @repository.destroy(area)
        rescue ActiveRecord::InvalidForeignKey => e
          Rails.logger.error "Area destroy failed (FK constraint): id=#{area.id}, error=#{e.message}"
          return failure(["このエリアにはアカウントが関連付けられているため削除できません"], :conflict)
        end

        Rails.logger.info "Area destroyed: id=#{validation.value[:id]}, by_account=#{current_account.id}"
        Result.new(success?: true, message: "deleted", errors: [], status: :ok)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, message: nil, errors:, status:)
        end
    end
  end
end
