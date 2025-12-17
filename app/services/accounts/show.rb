module Services
  module Accounts
    class Show
      def call(params, current_account)
        validation = ::Contracts::Accounts::Show.call(params)
        return failure(validation.errors, :unprocessable_entity) unless validation.success?

        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(["権限がありません"], :forbidden) unless policy.admin_only?

        value = validation.value
        account = Services::Accounts::Repository.new.get_account(value[:id])
        return failure(["ID'#{value[:id]}のUSERは存在しません"], :not_found) unless account
        Result.new(success?: true, account:, errors: [], status: :ok)
      end

      private
        def failure(errors, status)
          Result.new(success?: false, account: nil, errors:, status:)
        end
    end
  end
end
