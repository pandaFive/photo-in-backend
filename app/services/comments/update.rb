# frozen_string_literal: true

module Services
  module Comments
    # コメント更新サービス
    #
    # 認可ルール:
    # - Admin: 全コメント更新可能
    # - Member: 自分のコメントのみ更新可能
    #
    # トランザクション + 悲観ロックで同時更新を防止
    class Update
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { id: Integer, comment: { content: String } }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Comments::Update.call(params)
        unless validation.success?
          Rails.logger.warn "Comment update validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        value = validation.value
        comment_id = value[:id]

        Comment.transaction do
          comment = @repository.find_by_id_with_lock(comment_id)
          unless comment
            Rails.logger.warn "Comment not found during update: id=#{comment_id}, by_account=#{current_account.id}"
            return failure(["ID'#{comment_id}'のコメントは存在しません"], :not_found)
          end

          policy = ::Policies::CommentPolicy.new(current_account)
          unless policy.can_modify?(comment)
            Rails.logger.warn "Comment update denied: id=#{comment.id}, by_account=#{current_account.id}"
            return failure(["このコメントを更新する権限がありません"], :forbidden)
          end

          update_attrs = value.except(:id).compact
          unless @repository.update(comment, update_attrs)
            Rails.logger.warn "Comment update failed: id=#{comment.id}, errors=#{comment.errors.full_messages.join(', ')}"
            return failure(comment.errors.full_messages, :unprocessable_entity)
          end

          # account関連を読み込み直す（Presenter用）
          updated_id = comment.id
          comment = @repository.find_by_id(updated_id)
          unless comment
            Rails.logger.error "Comment vanished after update: id=#{updated_id}, by_account=#{current_account.id}"
            return failure(["コメントの更新後にデータが見つかりませんでした"], :internal_server_error)
          end

          Rails.logger.info "Comment updated: id=#{comment.id}, by_account=#{current_account.id}"
          return Result.new(success?: true, comment:, errors: [], status: :ok)
        end
      rescue ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout => e
        Rails.logger.error "Comment update lock error: id=#{params[:id]}, error=#{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再試行してください。"], :service_unavailable)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Comment update DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, comment: nil, errors:, status:)
        end
    end
  end
end
