# frozen_string_literal: true

module Services
  module Authentications
    # Unified Result for Authentications services.
    # account: 認証されたアカウント
    Result = Struct.new(:success?, :account, :errors, :status, keyword_init: true)
  end
end
