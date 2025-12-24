# frozen_string_literal: true

module Services
  module Accounts
    class Index
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(current_account)
        policy = ::Policies::AccountPolicy.new(current_account)
        return Result.new(success?: false, accounts: [], errors: ["権限がありません"], status: :forbidden) unless policy.admin_only?

        accounts = @repository.list_members
        data = @repository.get_accounts_stats(accounts)
        Result.new(success?: true, accounts:, data:, errors: [], status: :ok)
      end
    end
  end
end
