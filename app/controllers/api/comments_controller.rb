class Api::CommentsController < ApplicationController
  def index
    comments = Comment.where(id: params[:id])

    render json: comments
  end

  def show
    comment = Comment.find(params[:id])

    render json: comment
  end

  def create
    comment = Comment.new(create_params)

    if comment.save
      render json: comment
    else
      render json: { message: comment.errors, status: 422 }, status: :unprocessable_entity
    end
  end

  def update
    comment = Comment.find(params[:id])
    comment.update(update_params)

    render json: comment
  end

  def destroy
    comment = Comment.find(params[:id])

    comment.destroy
  end

  private
    def create_params
      params.require(:comment).permit(:content, :task_id, :account_id)
    end
end
