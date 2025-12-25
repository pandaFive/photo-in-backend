# frozen_string_literal: true

module Services
  module Accounts
    # アカウント更新ユースケース
    #
    # 管理者のみ実行可能
    class Update
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        # 認証チェック
        return failure(nil, ["認証が必要です"], :unauthorized) if current_account.nil?

        # Contract検証
        validation = ::Contracts::Accounts::Update.call(params)
        unless validation.success?
          Rails.logger.warn "Account update validation failed: #{validation.errors.join(', ')}"
          return failure(nil, validation.errors, :unprocessable_entity)
        end

        value = validation.value

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(nil, ["権限がありません"], :forbidden) unless policy.admin_only?

        # トランザクション内で更新（悲観ロック使用）
        update_attrs = value.except(:id).compact
        account = nil
        updated = false

        begin
          Account.transaction do
            account = @repository.get_account_with_lock(value[:id])
            unless account
              # トランザクション内でnot_foundを返すためにRollback
              raise ActiveRecord::Rollback
            end

            updated = @repository.update(account, update_attrs)
            raise ActiveRecord::Rollback unless updated
          end
        rescue ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout => e
          Rails.logger.error "Account update lock error: id=#{value[:id]}, error=#{e.message}"
          return failure(nil, ["サーバーが混雑しています。しばらくしてから再試行してください。"], :service_unavailable)
        rescue ActiveRecord::StatementInvalid => e
          Rails.logger.error "Account update DB error: id=#{value[:id]}, error=#{e.message}"
          return failure(nil, ["データベースエラーが発生しました"], :internal_server_error)
        end

        # アカウントが見つからない場合
        return failure(nil, ["ID'#{value[:id]}'のアカウントは存在しません"], :not_found) unless account

        # 更新失敗時
        unless updated
          Rails.logger.warn "Account update failed: id=#{account.id}, errors=#{account.errors.full_messages.join(', ')}, by_account=#{current_account.id}"
          return failure(account, account.errors.full_messages.presence || ["更新に失敗しました"], :unprocessable_entity)
        end

        # ログに機密属性（password）を含めない
        logged_attrs = update_attrs.keys.reject { |k| k.to_s == "password" }.join(",")
        Rails.logger.info "Account updated: id=#{account.id}, attrs=#{logged_attrs}, by_account=#{current_account.id}"
        Result.new(success?: true, account:, errors: [], status: :ok)
      end

      private
        def failure(account, errors, status)
          Result.new(success?: false, account:, errors:, status:)
        end
    end
  end
end
