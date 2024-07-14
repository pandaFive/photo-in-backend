class Area < ApplicationRecord
  validates :name, presence: true, length: { maximum: 32 }

  has_many :account_areas
  has_many :accounts, through: :account_areas

  class << self
    def get_all_area
      res = Area.select(:id, :name)
      res
    end

    def getAreaId(title)
      area_names = Area.all.pluck(:name)
      area_name = area_names.select do |area|
        title.include? area
      end

      if area_name.empty?
        nil
      else
        id = Area.find_by(name: area_name[0]).id
        id
      end
    end
  end
end
