module Services
  module Accounts
    class Index
      def call(params)
        accounts = Account.where(role: "member")
        return 
      end

      private
        def failure(errors, status)
          Result.new(success?: false, account: nil, errors:, status:)
        end
    end
  end
end
