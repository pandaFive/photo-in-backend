module Services
  module Accounts
    class Show
      def call(params)
        account = Account.find_by(id: params[:id])
        return failure(["ID'#{params[:id]}のUSERは存在しません"]) unless account
        Result.new(success?: true, account:, errors: [], status: :ok)
      end

      private
        def failure(errors)
          Result.new(success?: false, account: nil, errors:, status: :not_found)
        end
    end
  end
end
