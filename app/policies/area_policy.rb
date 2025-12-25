# frozen_string_literal: true

module Policies
  class AreaPolicy
    def initialize(account)
      @account = account
    end

    # エリアの作成・更新・削除は admin のみ許可
    def admin_only?
      @account&.role == "admin"
    end
  end
end
