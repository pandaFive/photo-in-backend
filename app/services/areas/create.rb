# frozen_string_literal: true

module Services
  module Areas
    class Create
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Areas::Create.call(params)
        unless validation.success?
          Rails.logger.warn "Area create validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        policy = ::Policies::AreaPolicy.new(current_account)
        unless policy.admin_only?
          Rails.logger.warn "Area create unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"
          return failure(["権限がありません"], :forbidden)
        end

        area = @repository.build(name: validation.value[:name])
        unless @repository.save(area)
          Rails.logger.warn "Area create failed: name=#{validation.value[:name]}, errors=#{area.errors.full_messages.join(', ')}, by_account=#{current_account.id}"
          return failure(area.errors.full_messages, :unprocessable_entity)
        end

        Rails.logger.info "Area created: id=#{area.id}, name=#{area.name}, by_account=#{current_account.id}"
        Result.new(success?: true, area:, errors: [], status: :created)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Area create DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, area: nil, errors:, status:)
        end
    end
  end
end
