class Tag < ApplicationRecord
  validate :name, presence: true, length: { maximum: 32 }

  has_many :account_tags
  has_many :accounts, through: :account_tags
end
