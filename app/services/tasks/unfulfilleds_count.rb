# frozen_string_literal: true

module Services
  module Tasks
    # アクティブサイクル数取得
    class UnfulfilledsCount
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        count = @repository.count_unfulfilleds
        success(count)
      rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
        log_error("データベース接続失敗", e, current_account)
        failure(["データベース接続に失敗しました。しばらくしてから再試行してください。"], :service_unavailable)
      rescue ActiveRecord::StatementInvalid, ActiveRecord::QueryCanceled => e
        log_error("データベースクエリ失敗", e, current_account)
        failure(["データの取得に失敗しました。"], :internal_server_error)
      end

      private
        def success(count)
          UnfulfilledsCountResult.new(success?: true, count:, errors: [], status: :ok)
        end

        def failure(errors, status)
          UnfulfilledsCountResult.new(success?: false, count: nil, errors:, status:)
        end

        def log_error(message, error, account)
          Rails.logger.error(
            message:,
            error_class: error.class.name,
            error_message: error.message,
            account_id: account&.id
          )
        end
    end

    # UnfulfilledsCount専用Result
    UnfulfilledsCountResult = Struct.new(:success?, :count, :errors, :status, keyword_init: true)
  end
end
