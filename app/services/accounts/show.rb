# frozen_string_literal: true

module Services
  module Accounts
    class Show
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        validation = ::Contracts::Accounts::Show.call(params)
        return failure(nil, validation.errors, :unprocessable_entity) unless validation.success?

        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(nil, ["権限がありません"], :forbidden) unless policy.admin_only?

        value = validation.value
        account = @repository.get_account(value[:id])
        return failure(nil, ["ID'#{value[:id]}のUSERは存在しません"], :not_found) unless account
        Result.new(success?: true, account:, errors: [], status: :ok)
      end

      private
        def failure(account, errors, status)
          Result.new(success?: false, account:, errors:, status:)
        end
    end
  end
end
