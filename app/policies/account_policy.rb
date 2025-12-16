module Policies
  class AccountPolicy
    def initialize(account)
      @account = account
    end

    def create?
      @account&.role == "admin"
    end
  end
end
