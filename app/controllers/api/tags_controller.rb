class Api::TagsController < ApplicationController
  def index
    tags = Tag.all

    render json: tags
  end

  def create
    tag = Tag.new(create_params)

    if tag.save
      render json: tag
    else
      render json: { message: tag.errors, status: 422 }, status: :unprocessable_entity
    end
  end

  def update
    tag = Tag.find(params[:id])
    tag.update(create_params)

    render json: tag
  end

  def destroy
    tag = Tag.find(params[:id])

    tag.destroy
  end

  private
    def create_params
      params.require(:tag).permit(:name)
    end
end
