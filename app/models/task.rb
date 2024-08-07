class Task < ApplicationRecord
  belongs_to :area

  validates :task_title, presence: true

  has_many :tag_tasks
  has_many :tags, through: :tag_tasks

  has_many :assign_cycles
  has_many :assign_histories, through: :assign_cycles

  def add_tag(tag)
    self.tags << tag
  end

  def remove_tag(tag)
    self.tags.destroy(tag)
  end

  def create_new_cycle
    # すでにcycleが存在している場合非アクティブ化
    AssignCycle.where(task_id: self.id).each do |cycle|
      cycle.deactivation
    end

    cycle = self.assign_cycles.create
    cycle
  end

  class << self
    # idのAccountに現在アサインされているタスクを取得する
    def getAccountAssignTasks(id)
      tasks = Task.joins(:area).joins(assign_cycles: :assign_histories)
                .where(assign_histories: { account_id: id })
                .where(assign_cycles: { is_active: true })
                .where(assign_histories: { ng: false })
                .where(assign_histories: { completed: false })
                .select("tasks.id AS id, tasks.task_title AS title, areas.name AS area_name, assign_histories.id AS history_id, assign_cycles.id AS assign_cycle_id, assign_histories.created_at AS created_at")
      tasks
    end

    def getActiveTasks
      # tasks = Task.joins(:area).joins(assign_cycles: :assign_histories)
      #           .where(assign_cycles: { is_active: true })
      #           .select("tasks.id AS id, tasks.task_title AS title, areas.name AS area_name, assign_histories.id AS history_id, assign_cycles.id AS assign_cycle_id, tasks.created_at AS created_at")

      tasks = Task.joins(:area).joins(:assign_cycles)
                .where(assign_cycles: { is_active: true })
                .select("tasks.id AS id, tasks.task_title AS title, areas.name AS area_name, assign_cycles.id AS assign_cycle_id, tasks.created_at AS created_at")

      tasks
    end

    def getNGTasks
      # 実行中のタスクを取得する
      continue_task = Task.joins(:area).joins(assign_cycles: :assign_histories)
                .where(assign_cycles: { is_active: true })
                .where(assign_histories: { ng: false })
                .select(:id)

      # 一つ以上のNGがあり現在実行中にないタスクを取得する
      task = Task.joins(:area).joins(assign_cycles: :assign_histories)
                .where(assign_cycles: { is_active: true })
                .where.not(id: continue_task)
                .select("tasks.id AS id, tasks.task_title AS title, areas.name AS area_name, assign_histories.id AS history_id, assign_cycles.id AS assign_cycle_id, tasks.created_at AS created_at")

      task
    end

    def getAreaId(title)
      puts "check"
      area_names = Area.all.pluck(:name)
      area_name = area_names.select do |area|
        title.include? area
      end
      if area_name.length == 0
        return nil
      end
      id = Area.find_by(name: area_name[0]).id
      id
    end
  end
end
