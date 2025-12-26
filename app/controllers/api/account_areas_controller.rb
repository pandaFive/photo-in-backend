# frozen_string_literal: true

class Api::AccountAreasController < ApplicationController
  before_action :authenticated?

  # POST /api/account_areas
  # アカウントにエリアを追加
  def create
    result = ::Services::AccountAreas::Create.new.call(create_params, @current_account)
    render_result(result) do
      ::Presenters::AreaPresenter.render_areas(result.areas)
    end
  end

  # DELETE /api/account_areas/:id
  # アカウントからエリアを削除
  def destroy
    result = ::Services::AccountAreas::Destroy.new.call(destroy_params, @current_account)
    render_result(result) do
      ::Presenters::AreaPresenter.render_areas(result.areas)
    end
  end

  private
    def create_params
      params.permit(:account_id, :area_id).to_h.symbolize_keys
    end

    def destroy_params
      params.permit(:account_id, :area_id).to_h.symbolize_keys
    end
end
