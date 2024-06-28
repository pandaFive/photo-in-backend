class Comment < ApplicationRecord
  belongs_to :account
  belongs_to :assign_cycle

  def mutate_render
    comment = Comment.joins(:account)
                .where(id: self.id)
                .select("comments.id AS id, comments.content AS content, comments.updated_at AS updatedAt, accounts.name AS accountName, comments.assign_cycle_id AS cycleId, accounts.role AS role")

    comment
  end

  class << self
    def get_member_comments(cycle_id, account_id)
      comments = Comment.joins(:account)
                    .where(assign_cycle_id: cycle_id)
                    .where(account_id:)
                    .select("comments.id AS id, comments.content AS content, comments.updated_at AS updatedAt, accounts.name AS accountName, comments.assign_cycle_id AS cycleId, accounts.role AS role")

      comments
    end
  end
end
