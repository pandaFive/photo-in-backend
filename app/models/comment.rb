class Comment < ApplicationRecord
  belongs_to :account
  belongs_to :task

  def mutate_render
    comment = Comment.joins(:account)
                .where(id: self.id)
                .select("comments.id AS id, comments.content AS content, comments.updated_at AS updatedAt, accounts.name AS name, comments.task_id AS taskId, accounts.role AS role")

    comment
  end

  class << self
    def get_member_comments(task_id, account_id)
      account = Account.find(account_id)

      if account.role == "admin"
        comments = Comment.joins(:account)
                      .where(task_id:)
                      .select("comments.id AS id, comments.content AS content, comments.updated_at AS updatedAt, accounts.name AS name, comments.task_id AS taskId, accounts.role AS role")
        comments
      else
        comments = Comment.joins(:account)
                      .where(task_id:)
                      .where("account_id = ? OR role = ?", account_id, "admin")
                      .select("comments.id AS id, comments.content AS content, comments.updated_at AS updatedAt, accounts.name AS name, comments.task_id AS taskId, accounts.role AS role")
        comments
      end
    end
  end
end
