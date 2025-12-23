class Api::AuthenticationsController < ApplicationController
  def login
    account = Account.find_by(name: params[:account][:name])

    if account && account.authenticate(params[:account][:password])
      render json: ::Presenters::AccountPresenter.render_auth(account)
    else
      render json: { errors: ["Unprocessable Entity"], status: 422 }, status: :unprocessable_entity
    end
  end
end
