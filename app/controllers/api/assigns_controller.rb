# frozen_string_literal: true

class Api::AssignsController < ApplicationController
  # TODO: indexメソッドの実装が必要な場合は追加してください
  # 現在はcycle_createのみが使用されています

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
