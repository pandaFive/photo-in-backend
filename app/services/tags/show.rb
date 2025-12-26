# frozen_string_literal: true

module Services
  module Tags
    # タグ詳細取得サービス
    #
    # 認可: 全認証ユーザー
    class Show
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { id: String|Integer } IDパラメータ
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        validation = ::Contracts::Tags::Show.call(params)
        unless validation.success?
          Rails.logger.warn "Tag show validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        tag = @repository.find_by_id(validation.value[:id])
        unless tag
          Rails.logger.warn "Tag not found: id=#{validation.value[:id]}, requested_by=#{current_account.id}"
          return failure(["ID'#{validation.value[:id]}'のタグは存在しません"], :not_found)
        end

        Result.new(success?: true, tag:, errors: [], status: :ok)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Tag show DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, tag: nil, errors:, status:)
        end
    end
  end
end
