class Tag < ApplicationRecord
  validates :name, presence: true, length: { maximum: 32 }

  has_many :tag_accounts
  has_many :accounts, through: :tag_accounts
end
