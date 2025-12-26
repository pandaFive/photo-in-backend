# frozen_string_literal: true

module Presenters
  # コメントのレスポンス整形を担当
  #
  # account 情報を含めた形式で返却
  class CommentPresenter
    class << self
      # 単一コメントをレスポンス形式に変換
      # @param comment [Comment] コメントオブジェクト（account関連を含む）
      # @return [Hash, nil]
      def render_comment(comment)
        if comment.nil?
          Rails.logger.warn "CommentPresenter.render_comment received nil comment"
          return nil
        end

        # orphanedコメント（削除されたアカウント）の警告
        if comment.account.nil?
          Rails.logger.warn "CommentPresenter: comment id=#{comment.id} has nil account (orphaned)"
        end

        {
          id: comment.id,
          content: comment.content,
          task_id: comment.task_id,
          account_id: comment.account_id,
          account_name: comment.account&.name,
          account_role: comment.account&.role,
          updated_at: comment.updated_at&.iso8601
        }
      end

      # コメント一覧をレスポンス形式に変換
      # @param comments [Array<Comment>] コメント配列
      # @return [Array<Hash>]
      def render_comments(comments)
        if comments.nil?
          Rails.logger.warn "CommentPresenter.render_comments received nil comments"
          return []
        end

        comments.map { |comment| render_comment(comment) }
      end
    end
  end
end
