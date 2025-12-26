# frozen_string_literal: true

module Services
  module Comments
    # Comment モデルへのデータアクセスを担当するリポジトリ
    #
    # Service 層から直接 ActiveRecord を呼び出さないための抽象化層
    # テスト時にモック化することで DB 非依存のテストが可能
    # N+1クエリ防止のためaccount情報をeager load
    class Repository
      # Admin用: タスクの全コメントを取得（account情報含む）
      # @param task_id [Integer] タスクID
      # @return [ActiveRecord::Relation<Comment>]
      def get_comments_for_admin(task_id)
        Rails.logger.debug "Repository: get_comments_for_admin task_id=#{task_id}"
        Comment.includes(:account).where(task_id:).order(updated_at: :desc)
      end

      # Member用: 自分とAdminのコメントのみ取得（account情報含む）
      # @param task_id [Integer] タスクID
      # @param account_id [Integer] 閲覧者のアカウントID
      # @return [ActiveRecord::Relation<Comment>]
      def get_comments_for_member(task_id, account_id)
        Rails.logger.debug "Repository: get_comments_for_member task_id=#{task_id}, account_id=#{account_id}"
        Comment.joins(:account)
               .includes(:account)
               .where(task_id:)
               .where("comments.account_id = ? OR accounts.role = ?", account_id, "admin")
               .order(updated_at: :desc)
      end

      # IDでコメントを検索（account情報含む）
      # @param id [Integer] コメントID
      # @return [Comment, nil]
      def find_by_id(id)
        Rails.logger.debug "Repository: find_by_id id=#{id}"
        Comment.includes(:account).find_by(id:)
      end

      # IDでコメントを悲観ロック付きで検索
      # 同時更新を防ぐため、update/destroy 処理で使用
      # @param id [Integer] コメントID
      # @return [Comment, nil]
      def find_by_id_with_lock(id)
        Rails.logger.debug "Repository: find_by_id_with_lock id=#{id}"
        Comment.lock.find_by(id:)
      end

      # 新規 Comment インスタンスを生成（未保存）
      # @param attrs [Hash] コメント属性
      # @return [Comment]
      def build(attrs)
        Rails.logger.debug "Repository: build attrs=#{attrs.keys.join(', ')}"
        Comment.new(attrs)
      end

      # Comment を永続化
      # @param comment [Comment] 保存対象のコメント
      # @return [Boolean] 保存成功/失敗
      def save(comment)
        Rails.logger.debug "Repository: save comment_id=#{comment.id || 'new'}"
        result = comment.save
        Rails.logger.debug "Repository: save result=#{result}"
        result
      end

      # Comment の属性を更新
      # @param comment [Comment] 更新対象のコメント
      # @param attrs [Hash] 更新する属性
      # @return [Boolean] 更新成功/失敗
      def update(comment, attrs)
        Rails.logger.debug "Repository: update id=#{comment.id}, attrs=#{attrs.keys.join(', ')}"
        result = comment.update(attrs)
        Rails.logger.debug "Repository: update result=#{result}"
        result
      end

      # Comment を削除
      # @param comment [Comment] 削除対象のコメント
      # @return [Comment, false] 削除されたコメントオブジェクト（frozen状態）または失敗時false
      def destroy(comment)
        Rails.logger.debug "Repository: destroy id=#{comment.id}"
        result = comment.destroy
        Rails.logger.debug "Repository: destroy result=#{result.frozen? ? 'success' : 'failed'}"
        result
      end

      # タスクが存在するか確認
      # @param task_id [Integer] タスクID
      # @return [Boolean]
      def task_exists?(task_id)
        Rails.logger.debug "Repository: task_exists? task_id=#{task_id}"
        Task.exists?(id: task_id)
      end
    end
  end
end
