# frozen_string_literal: true

module Presenters
  class TaskPresenter
    def self.render_task(task)
      {
        id: task.id,
        task_title: task.task_title,
        area_id: task.area_id,
        area_name: task.area&.name,
        created_at: task.created_at,
        updated_at: task.updated_at
      }
    end

    def self.render_tasks(tasks)
      tasks.map { |task| render_task(task) }
    end

    # アクティブタスク一覧用（get_active_tasksの結果をフォーマット）
    # titleをtask_titleに変換して返す
    def self.render_active_tasks(tasks)
      tasks.map do |task|
        {
          id: task.id,
          task_title: task.title,
          area_name: task.area_name,
          assign_cycle_id: task.assign_cycle_id,
          created_at: task.created_at
        }
      end
    end

    # NGタスク一覧用（get_ng_tasksの結果をフォーマット）
    # titleをtask_titleに変換して返す
    def self.render_ng_tasks(tasks)
      tasks.map do |task|
        {
          id: task.id,
          task_title: task.title,
          area_name: task.area_name,
          history_id: task.history_id,
          assign_cycle_id: task.assign_cycle_id,
          created_at: task.created_at
        }
      end
    end

    # タスクに紐付くタグ一覧をフォーマット
    def self.render_tags(task)
      task.tags.map do |tag|
        {
          id: tag.id,
          name: tag.name
        }
      end
    end
  end
end
