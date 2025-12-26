# frozen_string_literal: true

class Api::CommentsController < ApplicationController
  before_action :authenticated?

  def index
    result = ::Services::Comments::Index.new.call(index_params, @current_account)
    render_result(result) { ::Presenters::CommentPresenter.render_comments(result.comments) }
  end

  def show
    result = ::Services::Comments::Show.new.call(show_params, @current_account)
    render_result(result) { ::Presenters::CommentPresenter.render_comment(result.comment) }
  end

  def create
    result = ::Services::Comments::Create.new.call(create_params, @current_account)
    render_result(result) { ::Presenters::CommentPresenter.render_comment(result.comment) }
  end

  def update
    result = ::Services::Comments::Update.new.call(update_params, @current_account)
    render_result(result) { ::Presenters::CommentPresenter.render_comment(result.comment) }
  end

  def destroy
    result = ::Services::Comments::Destroy.new.call(destroy_params, @current_account)
    render_result(result) { { message: result.message } }
  end

  private
    def index_params
      { task_id: params[:taskId] }
    end

    def show_params
      { id: params[:id] }
    end

    def create_params
      { comment: params.require(:comment).permit(:content, :task_id) }
    end

    def update_params
      { id: params[:id], comment: params.require(:comment).permit(:content) }
    end

    def destroy_params
      { id: params[:id] }
    end
end
