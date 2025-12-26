# frozen_string_literal: true

module Services
  module Tags
    # タグ一覧取得サービス
    #
    # 認可: 全認証ユーザー
    class Index
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        tags = @repository.all_tags
        Result.new(success?: true, tags:, errors: [], status: :ok)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Tag index DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, tags: nil, errors:, status:)
        end
    end
  end
end
