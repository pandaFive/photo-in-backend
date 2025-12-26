# frozen_string_literal: true

module Services
  module AccountAreas
    # アカウントからエリアを削除するサービス
    #
    # 認可: admin のみ
    class Destroy
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
          Rails.logger.warn "AccountArea destroy unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"
          return failure(["権限がありません"], :forbidden)
        end

        # Contract検証
        validation = ::Contracts::AccountAreas::Destroy.call(params)
        unless validation.success?
          Rails.logger.warn "AccountArea destroy validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        account_id = validation.value[:account_id]
        area_id = validation.value[:area_id]

        # アカウント取得
        account = @repository.find_account(account_id)
        if account.nil?
          Rails.logger.warn "Account not found for area remove: account_id=#{account_id}"
          return failure(["アカウントが見つかりません"], :not_found)
        end

        # エリア取得
        area = @repository.find_area(area_id)
        if area.nil?
          Rails.logger.warn "Area not found for account area remove: area_id=#{area_id}"
          return failure(["エリアが見つかりません"], :not_found)
        end

        # 紐付いているか確認
        unless @repository.area_exists?(account, area)
          Rails.logger.warn "Area not found in account: account_id=#{account_id}, area_id=#{area_id}"
          return failure(["このエリアはアカウントに紐付いていません"], :not_found)
        end

        # エリア削除
        @repository.remove_area(account, area)

        Rails.logger.info "Area removed from account: account_id=#{account_id}, area_id=#{area_id}, by_admin=#{current_account.id}"
        areas = @repository.get_areas(account)
        success(areas)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "AccountArea destroy DB error: #{e.message}"
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
