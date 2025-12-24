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
    # すでにcycleが存在している場合、一括で非アクティブ化
    AssignCycle.where(task_id: id).update_all(is_active: false)

    assign_cycles.create
  end

  # 指定されたアカウントが現在のタスク担当者かどうかを判定
  # 最新のAssignCycleの最新のAssignHistoryのaccount_idと比較
  def current_assignee?(account)
    return false if account.nil?

    # 単一クエリで最新の担当者IDを取得（N+1回避）
    current_account_id = AssignHistory
      .joins(:assign_cycle)
      .where(assign_cycles: { task_id: id })
      .order("assign_cycles.id DESC, assign_histories.id DESC")
      .limit(1)
      .pick(:account_id)

    current_account_id == account.id
  end

  class << self
    # idのAccountに現在アサインされているタスクを取得する
    def get_account_assign_tasks(id)
      Task.joins(:area).joins(assign_cycles: :assign_histories)
          .where(assign_histories: { account_id: id })
          .where(assign_cycles: { is_active: true })
          .where(assign_histories: { ng: false })
          .where(assign_histories: { completed: false })
          .select("tasks.id AS id, tasks.task_title AS title, areas.name AS area_name, assign_histories.id AS history_id, assign_cycles.id AS assign_cycle_id, assign_histories.created_at AS created_at")
    end

    def get_active_tasks
      Task.joins(:area).joins(:assign_cycles)
          .where(assign_cycles: { is_active: true })
          .select("tasks.id AS id, tasks.task_title AS title, areas.name AS area_name, assign_cycles.id AS assign_cycle_id, tasks.created_at AS created_at")
    end

    def get_ng_tasks
      # 実行中のタスクを取得する
      continue_task = Task.joins(:area).joins(assign_cycles: :assign_histories)
                          .where(assign_cycles: { is_active: true })
                          .where(assign_histories: { ng: false })
                          .select(:id)

      # 一つ以上のNGがあり現在実行中にないタスクを取得する
      Task.joins(:area).joins(assign_cycles: :assign_histories)
          .where(assign_cycles: { is_active: true })
          .where.not(id: continue_task)
          .select("tasks.id AS id, tasks.task_title AS title, areas.name AS area_name, assign_histories.id AS history_id, assign_cycles.id AS assign_cycle_id, tasks.created_at AS created_at")
    end
  end
end
