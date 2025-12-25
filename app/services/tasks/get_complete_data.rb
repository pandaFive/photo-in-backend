# frozen_string_literal: true

module Services
  module Tasks
    # 過去1週間の完了データ取得
    class GetCompleteData
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        data = @repository.get_completed_past_week
        success(data)
      rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
        log_error("データベース接続失敗", e, current_account)
        failure(["データベース接続に失敗しました。しばらくしてから再試行してください。"], :service_unavailable)
      rescue ActiveRecord::StatementInvalid, ActiveRecord::QueryCanceled => e
        log_error("データベースクエリ失敗", e, current_account)
        failure(["データの取得に失敗しました。"], :internal_server_error)
      end

      private
        def success(data)
          GetCompleteDataResult.new(success?: true, data:, errors: [], status: :ok)
        end

        def failure(errors, status)
          GetCompleteDataResult.new(success?: false, data: nil, errors:, status:)
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

    # GetCompleteData専用Result
    GetCompleteDataResult = Struct.new(:success?, :data, :errors, :status, keyword_init: true)
  end
end
