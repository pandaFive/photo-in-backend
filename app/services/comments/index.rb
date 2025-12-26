# frozen_string_literal: true

module Services
  module Comments
    # コメント一覧取得サービス
    #
    # 認可ルール:
    # - Admin: タスクの全コメントを取得
    # - Member: 自分のコメント + Admin作成コメントのみ取得
    class Index
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { task_id: Integer }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Comments::Index.call(params)
        unless validation.success?
          Rails.logger.warn "Comment index validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        task_id = validation.value[:task_id]

        unless @repository.task_exists?(task_id)
          Rails.logger.warn "Task not found for comments: task_id=#{task_id}, requested_by=#{current_account.id}"
          return failure(["ID'#{task_id}'のタスクは存在しません"], :not_found)
        end

        comments = if current_account.role == "admin"
          @repository.get_comments_for_admin(task_id)
        else
          @repository.get_comments_for_member(task_id, current_account.id)
        end

        Result.new(success?: true, comments:, errors: [], status: :ok)
      rescue ActiveRecord::LockWaitTimeout => e
        Rails.logger.error "Comment index lock timeout: #{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再試行してください。"], :service_unavailable)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Comment index DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, comments: nil, errors:, status:)
        end
    end
  end
end
