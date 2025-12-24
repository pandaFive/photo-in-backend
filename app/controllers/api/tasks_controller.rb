class Api::TasksController < ApplicationController
  before_action :authenticated?, only: [:index, :show, :create, :update, :destroy]

  def index
    result = ::Services::Tasks::Index.new.call(index_params, @current_account)
    render_result(result) do
      presenter_method = params[:type] == "ng" ? :render_ng_tasks : :render_active_tasks
      ::Presenters::TaskPresenter.send(presenter_method, result.tasks)
    end
  end

  def show
    result = ::Services::Tasks::Show.new.call(show_params, @current_account)
    render_result(result) do
      ::Presenters::TaskPresenter.render_task(result.task)
    end
  end

  def create
    result = ::Services::Tasks::Create.new.call(create_params.to_h.symbolize_keys, @current_account)
    render_result(result) do
      ::Presenters::TaskPresenter.render_task(result.task)
    end
  end

  def update
    result = ::Services::Tasks::Update.new.call(update_params, @current_account)
    render_result(result) do
      ::Presenters::TaskPresenter.render_task(result.task)
    end
  end

  def destroy
    result = ::Services::Tasks::Destroy.new.call(destroy_params, @current_account)
    render_result(result) do
      { message: result.message }
    end
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
      render json: { message: "failed", result: false }
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
    def index_params
      { type: params[:type] }
    end

    def show_params
      { id: params[:id] }
    end

    def create_params
      params.require(:task).permit(:task_title, :area_id)
    end

    def update_params
      { id: params[:id], task_title: params.dig(:task, :task_title) }
    end

    def destroy_params
      { id: params[:id] }
    end

    def complete_params
      params.require(:task).permit(:cycle_id)
    end
end
