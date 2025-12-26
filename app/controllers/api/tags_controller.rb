# frozen_string_literal: true

class Api::TagsController < ApplicationController
  before_action :authenticated?

  def index
    result = ::Services::Tags::Index.new.call(@current_account)
    render_result(result) { ::Presenters::TagPresenter.render_tags(result.tags) }
  end

  def show
    result = ::Services::Tags::Show.new.call(show_params, @current_account)
    render_result(result) { ::Presenters::TagPresenter.render_tag(result.tag) }
  end

  def create
    result = ::Services::Tags::Create.new.call(create_params, @current_account)
    render_result(result) { ::Presenters::TagPresenter.render_tag(result.tag) }
  end

  def update
    result = ::Services::Tags::Update.new.call(update_params, @current_account)
    render_result(result) { ::Presenters::TagPresenter.render_tag(result.tag) }
  end

  def destroy
    result = ::Services::Tags::Destroy.new.call(destroy_params, @current_account)
    render_result(result) { { message: result.message } }
  end

  private
    def show_params
      { id: params[:id] }
    end

    def create_params
      { tag: params.require(:tag).permit(:name) }
    end

    def update_params
      { id: params[:id], tag: params.require(:tag).permit(:name) }
    end

    def destroy_params
      { id: params[:id] }
    end
end
