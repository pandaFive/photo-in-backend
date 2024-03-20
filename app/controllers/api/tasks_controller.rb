class Api::TasksController < ApplicationController
  def index
    tasks = Task.all

    render json: tasks
  end

  def show
    task = Task.find(params[:id])

    render json: task
  end

  def create
    task = Task.new(create_params)
    task.area_id = 1

    if task.save
      cycle = task.create_new_cycle
      render json: task
    else
      render json: { message: task.errors, status: 422 }, status: :unprocessable_entity
    end
  end

  def update
    tag = Tag.find(params[:id])
    tag.update(update_params)

    render json: tag
  end

  def destroy
    tag = Tag.find(params[:id])

    tag.destroy
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
    task = Task.find(params[:task_id])
    task.update(is_complete: true)

    completed = Completed_tast.new(task_id: params[:task_id], account_id: params[:account_id])

    if completed.save
      render json: task
    else
      render json: { message: task.errors, status: 422 }, status: :unprocessable_entity
    end
  end

  private
    def create_params
      params.require(:task).permit(:task_title)
    end

    def update_params
      params.require(:task).permit(:task_title, :is_complete)
    end
end
