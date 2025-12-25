# frozen_string_literal: true

class Api::AreasController < ApplicationController
  before_action :authenticated?

  def index
    result = ::Services::Areas::Index.new.call(@current_account)
    render_result(result) { ::Presenters::AreaPresenter.render_areas(result.areas) }
  end

  def show
    result = ::Services::Areas::Show.new.call(show_params, @current_account)
    render_result(result) { ::Presenters::AreaPresenter.render_area(result.area) }
  end

  def create
    result = ::Services::Areas::Create.new.call(create_params, @current_account)
    render_result(result) { ::Presenters::AreaPresenter.render_area(result.area) }
  end

  def update
    result = ::Services::Areas::Update.new.call(update_params, @current_account)
    render_result(result) { ::Presenters::AreaPresenter.render_area(result.area) }
  end

  def destroy
    result = ::Services::Areas::Destroy.new.call(destroy_params, @current_account)
    render_result(result) { { message: result.message } }
  end

  private
    def show_params
      { id: params[:id] }
    end

    def create_params
      { area: params.require(:area).permit(:name) }
    end

    def update_params
      { id: params[:id], area: params.require(:area).permit(:name) }
    end

    def destroy_params
      { id: params[:id] }
    end
end
