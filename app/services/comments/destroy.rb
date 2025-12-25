# frozen_string_literal: true

module Services
  module Comments
    # コメント削除サービス
    #
    # 認可ルール:
    # - Admin: 全コメント削除可能
    # - Member: 自分のコメントのみ削除可能
    #
    # トランザクション + 悲観ロックで同時操作を防止
    class Destroy
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { id: Integer }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Comments::Destroy.call(params)
        unless validation.success?
          Rails.logger.warn "Comment destroy validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        comment_id = validation.value[:id]

        Comment.transaction do
          comment = @repository.find_by_id_with_lock(comment_id)
          unless comment
            Rails.logger.warn "Comment not found during destroy: id=#{comment_id}, by_account=#{current_account.id}"
            return failure(["ID'#{comment_id}'のコメントは存在しません"], :not_found)
          end

          policy = ::Policies::CommentPolicy.new(current_account)
          unless policy.can_modify?(comment)
            Rails.logger.warn "Comment destroy denied: id=#{comment.id}, by_account=#{current_account.id}"
            return failure(["このコメントを削除する権限がありません"], :forbidden)
          end

          @repository.destroy(comment)

          Rails.logger.info "Comment destroyed: id=#{comment_id}, by_account=#{current_account.id}"
          return Result.new(success?: true, message: "deleted", errors: [], status: :ok)
        end
      rescue ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout => e
        Rails.logger.error "Comment destroy lock error: id=#{params[:id]}, error=#{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再試行してください。"], :service_unavailable)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Comment destroy DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, message: nil, errors:, status:)
        end
    end
  end
end
