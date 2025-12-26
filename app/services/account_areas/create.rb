# frozen_string_literal: true

module Services
  module AccountAreas
    # アカウントにエリアを追加するサービス
    #
    # 認可: admin のみ
    class Create
      def initialize(repository: Repository.new)
        @repository = repository
      end

      # @param params [Hash] { account_id: Integer, area_id: Integer }
      # @param current_account [Account, nil] 現在のログインユーザー
      # @return [Result]
      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        unless policy.admin_only?
          Rails.logger.warn "AccountArea create unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"
          return failure(["権限がありません"], :forbidden)
        end

        # Contract検証
        validation = ::Contracts::AccountAreas::Create.call(params)
        unless validation.success?
          Rails.logger.warn "AccountArea create validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        account_id = validation.value[:account_id]
        area_id = validation.value[:area_id]

        # アカウント取得
        account = @repository.find_account(account_id)
        if account.nil?
          Rails.logger.warn "Account not found for area add: account_id=#{account_id}"
          return failure(["アカウントが見つかりません"], :not_found)
        end

        # エリア取得
        area = @repository.find_area(area_id)
        if area.nil?
          Rails.logger.warn "Area not found for account area add: area_id=#{area_id}"
          return failure(["エリアが見つかりません"], :not_found)
        end

        # 既に紐付いているか確認
        if @repository.area_exists?(account, area)
          Rails.logger.warn "Area already exists for account: account_id=#{account_id}, area_id=#{area_id}"
          return failure(["このエリアは既に追加されています"], :conflict)
        end

        # エリア追加
        unless @repository.add_area(account, area)
          Rails.logger.error "Failed to add area: account_id=#{account_id}, area_id=#{area_id}"
          return failure(["エリアの追加に失敗しました"], :unprocessable_entity)
        end

        Rails.logger.info "Area added to account: account_id=#{account_id}, area_id=#{area_id}, by_admin=#{current_account.id}"
        areas = @repository.get_areas(account)
        success(areas)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "AccountArea create DB error: #{e.message}"
        failure(["データベースエラーが発生しました"], :internal_server_error)
      end

      private
        def success(areas)
          Result.new(success?: true, areas:, message: nil, errors: [], status: :ok)
        end

        def failure(errors, status)
          Result.new(success?: false, areas: nil, message: "failed", errors:, status:)
        end
    end
  end
end
