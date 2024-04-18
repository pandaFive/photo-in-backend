class Api::AuthenticationsController < ApplicationController
  def login
    account = Account.find_by(name: params[:account][:name])

    if account && account.authenticate(params[:account][:password])
      render json: create_render_json(account)
    else
      render json: { status: 402 }, status: :unprocessable_entity
    end
  end
end
