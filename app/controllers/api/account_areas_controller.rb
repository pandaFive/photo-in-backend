class Api::AccountAreasController < ApplicationController
  def create
    account = Account.find(params[:account_id])
    area = Area.find(params[:area_id])

    account.add_area(area)

    render json: account.areas
  end

  def destroy
    account = Accout.find(params[:account_id])
    area = Area.find(params[:area_id])

    account.remove_area(area)
    render json: account.areas
  end
end
