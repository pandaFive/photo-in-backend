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

  def add_areas(areas)
    puts "check"
    puts areas
    areas.each do |area|
      add_area(Area.find(area.to_i))
    end
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

  def get_status
    total = AssignHistory.where(account_id: self.id)
              .where(completed: true)
              .count
    week = AssignHistory.where("completed_at > ?", 1.week.ago)
              .where(account_id: self.id)
              .count
    assign = AssignHistory.where(account_id: self.id)
              .where(ng: false)
              .where(completed: false)
              .count
    div = total == 0 ? 1 : total
    ng = AssignHistory.where(account_id: self.id).where(ng: true).count
    ng_rate = (1.0 * ng / div).floor(2)
    status = {
      id: self.id,
      capacity: self.capacity,
      createdAt: self.created_at,
      updatedAt: self.updated_at,
      name: self.name,
      # area: self.areas.pluck(:name).join(" "),
      area: self.areas.pluck(:name),
      total:,
      week:,
      ng_rate:,
      assign:
    }
    status
  end

  class << self
    def get_role_one_status
      res = []

      Account.where(role: "member").each do |ele|
        res.push(ele.get_status)
      end

      res
    end
  end
end
