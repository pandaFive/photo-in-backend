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
        return failure(nil, validation.errors, :unprocessable_entity) unless validation.success?

        value = validation.value

        # 認可チェック（admin_only）
        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(nil, ["権限がありません"], :forbidden) unless policy.admin_only?

        # アカウント取得
        account = @repository.get_account(value[:id])
        return failure(nil, ["ID'#{value[:id]}'のアカウントは存在しません"], :not_found) unless account

        # 更新実行
        update_attrs = value.except(:id).compact
        unless @repository.update(account, update_attrs)
          return failure(account, account.errors.full_messages, :unprocessable_entity)
        end

        Rails.logger.info "Account updated: id=#{account.id}, attrs=#{update_attrs.keys.join(',')}, by_account=#{current_account.id}"
        Result.new(success?: true, account:, errors: [], status: :ok)
      end

      private
        def failure(account, errors, status)
          Result.new(success?: false, account:, errors:, status:)
        end
    end
  end
end
