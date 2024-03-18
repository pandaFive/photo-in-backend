class Comment < ApplicationRecord
  belongs_to :task
  belongs_to :account
end
