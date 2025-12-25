# frozen_string_literal: true

module Policies
  # コメント操作の認可ポリシー
  #
  # 認可ルール:
  # - 閲覧(can_view?): admin / コメント所有者 / admin作成コメント
  # - 編集(can_modify?): admin / コメント所有者
  class CommentPolicy
    def initialize(account)
      @account = account
    end

    # コメントを閲覧できるか
    # @param comment [Comment] 対象コメント
    # @return [Boolean]
    def can_view?(comment)
      admin? || owner?(comment) || admin_comment?(comment)
    end

    # コメントを編集/削除できるか
    # @param comment [Comment] 対象コメント
    # @return [Boolean]
    def can_modify?(comment)
      admin? || owner?(comment)
    end

    private
      # @return [Boolean] 現在のユーザーがadminか
      def admin?
        @account&.role == "admin"
      end

      # @param comment [Comment] 対象コメント
      # @return [Boolean] 現在のユーザーがコメント所有者か
      def owner?(comment)
        @account&.id == comment.account_id
      end

      # @param comment [Comment] 対象コメント
      # @return [Boolean] コメントがadminによって作成されたか
      def admin_comment?(comment)
        comment.account&.role == "admin"
      end
  end
end
