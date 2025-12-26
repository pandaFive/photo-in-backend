# frozen_string_literal: true

module Services
  module Comments
    # コメント作成サービス
    #
    # セキュリティ:
    # - account_id は current_account から自動設定
    # - パラメータの account_id は無視（なりすまし防止）
    class Create
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { comment: { content: String, task_id: Integer } }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Comments::Create.call(params)
        unless validation.success?
          Rails.logger.warn "Comment create validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        task_id = validation.value[:task_id]
        unless @repository.task_exists?(task_id)
          Rails.logger.warn "Task not found for comment create: task_id=#{task_id}, by_account=#{current_account.id}"
          return failure(["ID'#{task_id}'のタスクは存在しません"], :not_found)
        end

        comment = @repository.build(
          content: validation.value[:content],
          task_id:,
          account_id: current_account.id
        )

        unless @repository.save(comment)
          Rails.logger.warn "Comment create failed: errors=#{comment.errors.full_messages.join(', ')}"
          return failure(comment.errors.full_messages, :unprocessable_entity)
        end

        # account関連を読み込み直す（Presenter用）
        saved_id = comment.id
        comment = @repository.find_by_id(saved_id)
        unless comment
          Rails.logger.error "Comment vanished after creation: id=#{saved_id}, task_id=#{task_id}, by_account=#{current_account.id}"
          return failure(["コメントの作成後にデータが見つかりませんでした"], :internal_server_error)
        end

        Rails.logger.info "Comment created: id=#{comment.id}, task_id=#{task_id}, by_account=#{current_account.id}"
        Result.new(success?: true, comment:, errors: [], status: :created)
      rescue ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout => e
        Rails.logger.error "Comment create lock error: error=#{e.message}"
        failure(["サーバーが混雑しています。しばらくしてから再試行してください。"], :service_unavailable)
      rescue ActiveRecord::InvalidForeignKey => e
        Rails.logger.error "Comment create FK error: #{e.message}"
        failure(["関連するタスクまたはアカウントが存在しません"], :conflict)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Comment create DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, comment: nil, errors:, status:)
        end
    end
  end
end
