# frozen_string_literal: true

module Services
  module Comments
    # コメント詳細取得サービス
    #
    # 認可ルール:
    # - Admin: 全コメント閲覧可能
    # - Member: 自分のコメント + Admin作成コメントのみ閲覧可能
    class Show
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { id: Integer }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Comments::Show.call(params)
        unless validation.success?
          Rails.logger.warn "Comment show validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        comment = @repository.find_by_id(validation.value[:id])
        unless comment
          Rails.logger.warn "Comment not found: id=#{validation.value[:id]}, requested_by=#{current_account.id}"
          return failure(["ID'#{validation.value[:id]}'のコメントは存在しません"], :not_found)
        end

        policy = ::Policies::CommentPolicy.new(current_account)
        unless policy.can_view?(comment)
          Rails.logger.warn "Comment view denied: id=#{comment.id}, by_account=#{current_account.id}"
          return failure(["このコメントを閲覧する権限がありません"], :forbidden)
        end

        Result.new(success?: true, comment:, errors: [], status: :ok)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Comment show DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, comment: nil, errors:, status:)
        end
    end
  end
end
