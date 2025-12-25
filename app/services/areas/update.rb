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
        area = @repository.find_by_id(value[:id])
        return failure(["ID'#{value[:id]}'のエリアは存在しません"], :not_found) unless area

        update_attrs = value.except(:id).compact
        unless @repository.update(area, update_attrs)
          Rails.logger.warn "Area update failed: id=#{area.id}, errors=#{area.errors.full_messages.join(', ')}"
          return failure(area.errors.full_messages, :unprocessable_entity)
        end

        Rails.logger.info "Area updated: id=#{area.id}, by_account=#{current_account.id}"
        Result.new(success?: true, area:, errors: [], status: :ok)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, area: nil, errors:, status:)
        end
    end
  end
end
