class Account < ApplicationRecord
  validates :name, presence: true, length: { maximum: 32 }
  has_secure_password
  validates :password, presence: true, length: { minimum: 8 }, allow_nil: true

  has_many :account_areas
  has_many :areas, through: :account_areas

  has_many :account_tags
  has_many :tags, through: :account_tags

  has_many :comments
  has_many :completed_tasks
  has_many :ng_histories
  has_many :assign_histories

  def add_area(area)
    self.areas << area
  end

  def remove_area(area)
    self.areas.destroy(area)
  end

  def add_tag(tag)
    self.tags << tag
  end

  def remove_tag(tag)
    self.tags.destroy(tag)
  end
end
