class AssignHistory < ApplicationRecord
  belongs_to :account
  belongs_to :assign_cycle
end
