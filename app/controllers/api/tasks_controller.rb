class Api::TasksController < ApplicationController
  def index
    type = params[:type]

    if type == "all"
      tasks = Task.get_active_tasks
      render json: tasks
    elsif type == "ng"
      tasks = Task.get_ng_tasks
      render json: tasks
    else
      render json: { message: "not type" }
    end
  end

  def show
    task = Task.find(params[:id])

    render json: task
  end

  def create
    result = ::Services::TaskCreationService.new(task_title: create_params[:task_title], area_id: create_params[:area_id]).call

    if result.success?
      render json: result.task
    else
      render json: { message: result.error_message, status: 422 }, status: result.error_status
    end
  end

  def update
    task = Task.find(params[:id])
    task.update(update_params)

    render json: task
  end

  def destroy
    task = Task.find(params[:id])

    task.destroy
  end

  def add_tag
    task = Task.find(params[:task_id])
    tag = Tag.find(params[:tag_id])

    task.add_tag(tag)

    render json: task.tags
  end

  def remove_tag
    task = Task.find(params[:task_id])
    tag = Tag.find(params[:tag_id])

    task.remove_tag(tag)

    render json: task.tags
  end

  def completed
    assign_history = AssignHistory.find(params[:id])
    assign_history.change_completed

    # if assign_history.completed
    if assign_history.completed
      render json: { message: "change completed", result: true }
    else
      render json: { message: "change failed", result: false }
    end
  end

  def create_new_cycle
    task = Task.find(params[:id])
    cycle = task.create_new_cycle
    if cycle.assign
      render json: task
    else
      render json: { status: 422 }
    end
  end

  def ng
    assign_history = AssignHistory.find(params[:id])
    assign_history.update(ng: true)
    cycle = AssignCycle.find(assign_history[:assign_cycle_id])
    if cycle.assign
      render json: { message: "complete", result: true }
    else
      render json: { message: "faild", result: false }
    end
  end

  def unfulfilleds_count
    res = AssignCycle.unfulfilleds
    render json: res.count
  end

  def get_complete_data
    result = AssignHistory.get_completed_past_week

    render json: result
  end

  def get_account_task
    id = params[:id]
    tasks = Task.get_account_assign_tasks(id)
    render json: tasks
  end

  private
    def create_params
      params.require(:task).permit(:task_title, :area_id)
    end

    def update_params
      params.require(:task).permit(:task_title, :is_complete)
    end

    def complete_params
      params.require(:task).permit(:cycle_id)
    end
end
