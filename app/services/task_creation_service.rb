class TaskCreationService
  Result = Struct.new(:success?, :task, :error_message, :error_status, keyword_init: true)

  def initialize(task_title:)
    @task_title = task_title
  end

  def call
    area_id = Area.get_area_id(@task_title)

    if area_id.nil?
      return Result.new(
        success?: false,
        error_message: "エリアが正しく設定されていない",
        error_status: :bad_request
      )
    end

    task = Task.new(task_title: @task_title, area_id:)

    unless task.save
      return Result.new(
        success?: false,
        error_message: task.errors.full_messages,
        error_status: :unprocessable_entity
      )
    end

    cycle = task.create_new_cycle
    unless cycle.assign
      return Result.new(
        success?: false,
        task:,
        error_message: "アサイン可能なアカウントがありません",
        error_status: :unprocessable_entity
      )
    end

    Result.new(success?: true, task:)
  end
end
