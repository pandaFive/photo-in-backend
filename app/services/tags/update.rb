# frozen_string_literal: true

module Services
  module Tags
    # タグ更新サービス
    #
    # 認可: admin のみ
    # 同時更新防止: 悲観ロック
    class Update
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { id: String|Integer, tag: { name: String } }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Tags::Update.call(params)
        unless validation.success?
          Rails.logger.warn "Tag update validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        policy = ::Policies::TagPolicy.new(current_account)
        unless policy.admin_only?
          Rails.logger.warn "Tag update unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"
          return failure(["権限がありません"], :forbidden)
        end

        value = validation.value
        update_attrs = value.except(:id).compact

        Tag.transaction do
          tag = @repository.find_by_id_with_lock(value[:id])
          unless tag
            Rails.logger.warn "Tag not found during update: id=#{value[:id]}, by_account=#{current_account.id}"
            return failure(["ID'#{value[:id]}'のタグは存在しません"], :not_found)
          end

          unless @repository.update(tag, update_attrs)
            Rails.logger.warn "Tag update failed: id=#{tag.id}, errors=#{tag.errors.full_messages.join(', ')}"
            return failure(tag.errors.full_messages, :unprocessable_entity)
          end

          Rails.logger.info "Tag updated: id=#{tag.id}, by_account=#{current_account.id}"
          Result.new(success?: true, tag:, errors: [], status: :ok)
        end
      rescue ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked => e
        Rails.logger.error "Tag update lock timeout: #{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再度お試しください"], :service_unavailable)
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.error "Tag update uniqueness error: #{e.message}"
        failure(["このタグは既に存在します"], :conflict)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Tag update DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, tag: nil, errors:, status:)
        end
    end
  end
end
