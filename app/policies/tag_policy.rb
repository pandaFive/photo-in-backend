# frozen_string_literal: true

module Policies
  # タグ操作の認可ポリシー
  #
  # 認可ルール:
  # - 閲覧(index/show): 全認証ユーザー
  # - 作成/更新/削除: admin のみ
  class TagPolicy
    def initialize(account)
      @account = account
    end

    # タグの作成・更新・削除は admin のみ許可
    # @return [Boolean]
    def admin_only?
      @account&.role == "admin"
    end
  end
end
