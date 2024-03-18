class Area < ApplicationRecord
  validates :name, presence: true, length: { maximum: 32 }

  has_many :account_areas
  has_many :accounts, through: :account_areas
end
