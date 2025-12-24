# frozen_string_literal: true

class Area < ApplicationRecord
  validates :name, presence: true, length: { maximum: 32 }

  has_many :account_areas
  has_many :accounts, through: :account_areas

  class << self
    def get_all_area
      Area.select(:id, :name)
    end

    def get_area_id(title)
      area_names = Area.all.pluck(:name)
      area_name = area_names.select do |area|
        title.include? area
      end

      return nil if area_name.empty?

      Area.find_by(name: area_name[0]).id
    end
  end
end
