class Api::CommentsController < ApplicationController
  def index
    comments = Comment.get_member_comments(params[:taskId], params[:accountId])

    render json: comments
  end

  def show
    comment = Comment.find(params[:id])

    render json: comment
  end

  def create
    comment = Comment.new(create_params)
    puts comment

    if comment.save
      render json: comment.mutate_render[0]
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

    if comment.destroy
      render json: { message: "complete" }, status: 200
    else
      render json: { message: "Delete failed" }, status: 400
    end
  end

  private
    def create_params
      params.require(:comment).permit(:content, :task_id, :account_id)
    end

    def update_params
      params.require(:comment).permit(:content, :task_id, :account_id)
    end
end
