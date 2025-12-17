module Services
  module Accounts
    class Destroy
      def initialize(repository: Repository.new)
        @repository = repository
      end

      def call(params, current_account)
        validation = ::Contracts::Accounts::Destroy.call(params)
        return failure(validation.errors, :unprocessable_entity) unless validation.success?

        policy = ::Policies::AccountPolicy.new(current_account)
        return failure(["権限がありません"], :forbidden) unless policy.admin_only?

        value = validation.value
        account = Account.find_by(id: value[:id])
        return failure(["ID'#{value[:id]}'のアカウントは存在しません"], :not_found) unless account

        account.destroy

        DestroyResult.new(success?: true, message: "deleted", errors: [], status: :ok)
      end

      private
        def failure(errors, status)
          DestroyResult.new(success?: false, message: nil, errors:, status:)
        end
    end

    DestroyResult = Struct.new(:success?, :message, :errors, :status, keyword_init: true)
  end
end
