# frozen_string_literal: true

module Services
  module Tasks
    # 未完了タスク数取得
    class UnfulfilledsCount
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # カウント取得
        count = @repository.count_unfulfilleds

        success(count)
      end

      private
        def success(count)
          UnfulfilledsCountResult.new(success?: true, count:, errors: [], status: :ok)
        end

        def failure(errors, status)
          UnfulfilledsCountResult.new(success?: false, count: nil, errors:, status:)
        end
    end

    # UnfulfilledsCount専用Result
    UnfulfilledsCountResult = Struct.new(:success?, :count, :errors, :status, keyword_init: true)
  end
end
