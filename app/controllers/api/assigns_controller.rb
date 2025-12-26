# frozen_string_literal: true

class Api::AssignsController < ApplicationController
  before_action :authenticated?

  # POST /api/tasks/assign/cycle
  # サイクルを作成し、自動割り当てを実行
  def cycle_create
    result = ::Services::Assigns::CycleCreate.new.call(cycle_create_params, @current_account)
    render_result(result) { ::Presenters::AssignCyclePresenter.render_cycle(result.cycle) }
  end

  private
    def cycle_create_params
      { assign_cycle: params.require(:assign_cycle).permit(:task_id) }
    end
end
