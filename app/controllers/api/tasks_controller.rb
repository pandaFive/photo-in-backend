# frozen_string_literal: true

class Api::TasksController < ApplicationController
  before_action :authenticated?, only: [:index, :show, :create, :update, :destroy, :add_tag, :remove_tag, :completed, :ng, :create_new_cycle, :unfulfilleds_count, :get_complete_data, :get_account_task]

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
    result = ::Services::Tasks::AddTag.new.call(tag_params, @current_account)
    render_result(result) do
      ::Presenters::TaskPresenter.render_tags(result.task)
    end
  end

  def remove_tag
    result = ::Services::Tasks::RemoveTag.new.call(tag_params, @current_account)
    render_result(result) do
      ::Presenters::TaskPresenter.render_tags(result.task)
    end
  end

  def completed
    result = ::Services::Tasks::Completed.new.call(completed_params, @current_account)
    if result.success?
      render json: { message: result.message, result: true }, status: result.status
    else
      render json: { message: "change failed", result: false, errors: result.errors }, status: result.status
    end
  end

  def create_new_cycle
    result = ::Services::Tasks::CreateNewCycle.new.call(create_new_cycle_params, @current_account)
    render_result(result) do
      ::Presenters::TaskPresenter.render_task(result.task)
    end
  end

  def ng
    result = ::Services::Tasks::Ng.new.call(ng_params, @current_account)
    if result.success?
      render json: { message: result.message, result: true }, status: result.status
    else
      render json: { message: "failed", result: false, errors: result.errors }, status: result.status
    end
  end

  def unfulfilleds_count
    result = ::Services::Tasks::UnfulfilledsCount.new.call(@current_account)
    if result.success?
      render json: result.count, status: result.status
    else
      Rails.logger.warn(message: "UnfulfilledsCount failed", errors: result.errors, account_id: @current_account&.id)
      render_error(result.errors, result.status)
    end
  end

  def get_complete_data
    result = ::Services::Tasks::GetCompleteData.new.call(@current_account)
    if result.success?
      render json: result.data, status: result.status
    else
      Rails.logger.error(message: "GetCompleteData failed", errors: result.errors, account_id: @current_account&.id)
      render_error(result.errors, result.status)
    end
  end

  def get_account_task
    result = ::Services::Tasks::GetAccountTask.new.call(get_account_task_params, @current_account)
    render_result(result) do
      ::Presenters::TaskPresenter.render_account_assign_tasks(result.tasks)
    end
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

    def tag_params
      { task_id: params[:id], tag_id: params[:tag_id] }
    end

    def completed_params
      { id: params[:id] }
    end

    def ng_params
      { id: params[:id] }
    end

    def create_new_cycle_params
      { id: params[:id] }
    end

    def complete_params
      params.require(:task).permit(:cycle_id)
    end

    def get_account_task_params
      { id: params[:id] }
    end
end
