# frozen_string_literal: true

module Services
  module Tags
    # タグ削除サービス
    #
    # 認可: admin のみ
    # 同時更新防止: 悲観ロック
    # FK制約: tag_accounts 関連があれば削除不可
    class Destroy
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { id: Integer }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Tags::Destroy.call(params)
        unless validation.success?
          Rails.logger.warn "Tag destroy validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        policy = ::Policies::TagPolicy.new(current_account)
        unless policy.admin_only?
          Rails.logger.warn "Tag destroy unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"
          return failure(["権限がありません"], :forbidden)
        end

        tag_id = validation.value[:id]

        Tag.transaction do
          tag = @repository.find_by_id_with_lock(tag_id)
          unless tag
            Rails.logger.warn "Tag not found during destroy: id=#{tag_id}, by_account=#{current_account.id}"
            return failure(["ID'#{tag_id}'のタグは存在しません"], :not_found)
          end

          unless @repository.destroy(tag)
            Rails.logger.error "Tag destroy failed (callbacks): id=#{tag.id}, errors=#{tag.errors.full_messages.join(', ')}"
            return failure(["タグの削除に失敗しました"], :unprocessable_entity)
          end

          Rails.logger.info "Tag destroyed: id=#{tag_id}, by_account=#{current_account.id}"
          Result.new(success?: true, message: "deleted", errors: [], status: :ok)
        end
      rescue ActiveRecord::InvalidForeignKey => e
        Rails.logger.error "Tag destroy failed (FK constraint): id=#{tag_id}, error=#{e.message}"
        failure(["このタグにはアカウントが関連付けられているため削除できません"], :conflict)
      rescue ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked => e
        Rails.logger.error "Tag destroy lock timeout: #{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再度お試しください"], :service_unavailable)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Tag destroy DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, message: nil, errors:, status:)
        end
    end
  end
end
