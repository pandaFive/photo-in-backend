class CompletedTask < ApplicationRecord
  belongs_to :task
  belongs_to :account
end
