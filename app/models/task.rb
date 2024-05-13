class Task < ApplicationRecord
  belongs_to :area

  validates :task_title, presence: true

  has_many :tag_tasks
  has_many :tags, through: :tag_tasks

  has_many :comments
  has_many :assign_cycles
  has_many :assign_histories, through: :assign_cycles

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

  class << self
    def getAccountTasks(id)
      tasks = Task.joins(:area).joins(:assign_cycles)
                .where(assign_cycles: { id: })
                .select("tasks.id AS id, tasks.task_title AS title, areas.name AS aera_name, assign_histories.id AS history_id, tasks.created_at AS created_at")
      tasks
    end

    def getAccountAssignTasks(id)
      tasks = Task.joins(:area).joins(assign_cycles: :assign_histories)
                .where(assign_histories: { account_id: id })
                .select("tasks.id AS id, tasks.task_title AS title, areas.name AS area_name, assign_histories.id AS history_id, tasks.created_at AS created_at")
      tasks
    end
  end
end
