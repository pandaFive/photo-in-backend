# frozen_string_literal: true

module Services
  module Areas
    class Show
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Areas::Show.call(params)
        unless validation.success?
          Rails.logger.warn "Area show validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        area = @repository.find_by_id(validation.value[:id])
        return failure(["ID'#{validation.value[:id]}'のエリアは存在しません"], :not_found) unless area

        Result.new(success?: true, area:, errors: [], status: :ok)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Area show DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, area: nil, errors:, status:)
        end
    end
  end
end
