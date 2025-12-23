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
  end
end
