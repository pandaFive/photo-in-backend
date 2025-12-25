# frozen_string_literal: true

module Services
  module Accounts
    # アカウント削除ユースケース
    #
    # 管理者のみ実行可能
    class Destroy
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Accounts::Destroy.call(params)
        unless validation.success?
          Rails.logger.warn "Account destroy validation failed: #{validation.errors.join(', ')}"
          return failure(validation.errors, :unprocessable_entity)
        end

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(["権限がありません"], :forbidden) unless policy.admin_only?

        # アカウント取得
        value = validation.value
        account = @repository.get_account(value[:id])
        return failure(["ID'#{value[:id]}'のアカウントは存在しません"], :not_found) unless account

        # 自己削除防止
        if account.id == current_account.id
          return failure(["自分自身のアカウントは削除できません"], :forbidden)
        end

        # 最後の管理者削除防止
        if account.role == "admin" && @repository.admin_count == 1
          return failure(["最後の管理者アカウントは削除できません"], :forbidden)
        end

        # 削除実行
        account_id = account.id
        account_name = account.name
        begin
          unless @repository.destroy(account)
            return failure(account.errors.full_messages, :unprocessable_entity)
          end
        rescue ActiveRecord::InvalidForeignKey => e
          Rails.logger.error "Account destroy failed (FK constraint): id=#{account_id}, error=#{e.message}"
          return failure(["このアカウントには関連データ（タスク割当、コメント等）が存在するため削除できません"], :conflict)
        end

        Rails.logger.info "Account destroyed: id=#{account_id}, name=#{account_name}, by_account=#{current_account.id}"
        Result.new(success?: true, message: "deleted", errors: [], status: :ok)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, message: nil, errors:, status:)
        end
    end
  end
end
