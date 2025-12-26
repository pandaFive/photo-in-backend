# frozen_string_literal: true

module Services
  module TagAccounts
    # アカウントにタグを追加するサービス
    #
    # 認可: admin のみ
    class Create
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { account_id: Integer, tag_id: Integer }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        unless policy.admin_only?
          Rails.logger.warn "TagAccount create unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"
          return failure(["権限がありません"], :forbidden)
        end

        # Contract検証
        validation = ::Contracts::TagAccounts::Create.call(params)
        unless validation.success?
          Rails.logger.warn "TagAccount create validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        account_id = validation.value[:account_id]
        tag_id = validation.value[:tag_id]

        # アカウント取得
        account = @repository.find_account(account_id)
        if account.nil?
          Rails.logger.warn "Account not found for tag add: account_id=#{account_id}"
          return failure(["アカウントが見つかりません"], :not_found)
        end

        # タグ取得
        tag = @repository.find_tag(tag_id)
        if tag.nil?
          Rails.logger.warn "Tag not found for account tag add: tag_id=#{tag_id}"
          return failure(["タグが見つかりません"], :not_found)
        end

        # 既に紐付いているか確認
        if @repository.tag_exists?(account, tag)
          Rails.logger.warn "Tag already exists for account: account_id=#{account_id}, tag_id=#{tag_id}"
          return failure(["このタグは既に追加されています"], :conflict)
        end

        # タグ追加
        unless @repository.add_tag(account, tag)
          Rails.logger.error "Failed to add tag: account_id=#{account_id}, tag_id=#{tag_id}"
          return failure(["タグの追加に失敗しました"], :unprocessable_entity)
        end

        Rails.logger.info "Tag added to account: account_id=#{account_id}, tag_id=#{tag_id}, by_admin=#{current_account.id}"
        tags = @repository.get_tags(account)
        success(tags)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "TagAccount create DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def success(tags)
          Result.new(success?: true, tags:, message: nil, errors: [], status: :ok)
        end

        def failure(errors, status)
          Result.new(success?: false, tags: nil, message: "failed", errors:, status:)
        end
    end
  end
end
