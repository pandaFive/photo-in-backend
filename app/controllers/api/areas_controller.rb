class Api::AreasController < ApplicationController
  def index
    areas = Area.all

    render json: areas
  end

  def show
    area = Area.find(params[:id])

    render json: area
  end

  def create
    area = Area.new(create_params)

    if area.save
      render json: area
    else
      render json: { message: area.errors, status: 422 }, status: :unprocessable_entity
    end
  end

  def update
    area = Area.find(params[:id])
    area.update(create_params)

    render json: area
  end

  def destroy
    area = Area.find(params[:id])

    area.destroy
  end

  private
    def create_params
      params.require(:area).permit(:name)
    end
end
