class Api::AssignsController < ApplicationController
  def index
  end

  def cycle_create
    cycle = AssignCycle.new(cycle_params)

    if cycle.save
      render json: cycle
    else
      render json: { message: cycle.errors, status: 422 }, status: :unprocessable_entity
    end
  end

  private
    def cycle_params
      params.require(:assign_cycle).permit(:task_id)
    end
end
