# frozen_string_literal: true

module Policies
  class AccountPolicy
    def initialize(account)
      @account = account
    end

    def admin_only?
      @account&.role == "admin"
    end
  end
end
