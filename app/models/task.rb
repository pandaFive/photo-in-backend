class Task < ApplicationRecord
  belongs_to :area

  validate :name, presence: true

  has_many :tag_tasks
  has_many :tags, through: tag_tasks

  has_many :comments
  has_many :assign_cycles

  def add_tag(tag)
    self.tags << tag
  end

  def remove_tag(tag)
    self.tags.destroy(tag)
  end

  def create_new_cycle
    cycle = self.assign_cycles.create
    cycle
  end
end
