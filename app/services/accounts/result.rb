module Services
  module Accounts
    # Unified Result for Accounts services.
    # account: single resource (for show/create, etc.)
    # accounts: collection (for index, etc.)
    # data: Accounts 以外の record (for index, etc.)
    Result = Struct.new(:success?, :account, :accounts, :data, :errors, :status, keyword_init: true)
  end
end
