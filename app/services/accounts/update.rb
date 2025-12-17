module Services
  module Accounts
    class Update
      def initialize(repository: Repository.new)
        @repository = repository
      end
      def call(params, current_account)
        validation = ::Contracts::Accounts::Update.call(params)
        return failure(nil, validation.errors, :unprocessable_entity) unless validation.success?

        value = validation.value

        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(nil, ["権限がありません"], :forbidden) unless policy.admin_only?

        account = @repository.get_account(value[:id])
        return failure(nil, ["ID'#{value[:id]}'のアカウントは存在しません"], :not_found) unless account
        update_attrs = value.except(:id).compact

        return failure(account, account.errors.full_messages, :unprocessable_entity) unless account.update(update_attrs)
        Result.new(success?: true, account:, errors: [], status: :ok)
      end

      private
        def failure(account, errors, status)
          Result.new(success?: false, account:, errors:, status:)
        end
    end
  end
end
