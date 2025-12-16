module Services
  module Accounts
    Result = Struct.new(:success?, :account, :errors, :status, keyword_init: true)
  end
end
