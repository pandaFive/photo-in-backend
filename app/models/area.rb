class Area < ApplicationRecord
  validates :name, presence: true, length: { maximum: 32 }

  has_many :account_areas
  has_many :accounts, through: :account_areas

  class << self
    def get_all_area
      res = Area.select(:id, :name)
      res
    end
  end
end
