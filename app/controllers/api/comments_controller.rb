class Api::CommentsController < ApplicationController
  def index
    comments = Comment.get_member_comments(params[:assignCycleId], params[:accountId])

    render json: comments
  end

  def show
    comment = Comment.find(params[:id])

    render json: comment
  end

  def create
    puts create_params
    comment = Comment.new(create_params)

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
      params.require(:comment).permit(:content, :assign_cycle_id, :account_id)
    end

    def update_params
      params.require(:comment).permit(:content, :assign_cycle_id, :account_id)
    end
end
