class Api::AccountsController < ApplicationController
  before_action :authenticated?, only: [:get, :create, :show, :index]

  def index
    result = ::Services::Accounts::Index.new.call(@current_account)
    if result.success?
      render json: ::Presenters::AccountPresenter.render_accounts(result.accounts, result.data), status: result.status
    else
      render json: { errors: result.errors, status: Rack::Utils::SYMBOL_TO_STATUS_CODE[result.status] }, status: result.status
    end
  end

  def get
    render json: ::Presenters::AccountPresenter.render_account(@current_account), status: :ok
  end

  def show
    result = ::Services::Accounts::Show.new.call(params.permit(:id).to_h.symbolize_keys, @current_account)

    if result.success?
      render json: ::Presenters::AccountPresenter.render_account(result.account), status: result.status
    else
      render json: { errors: result.errors, status: Rack::Utils::SYMBOL_TO_STATUS_CODE[result.status] }, status: result.status
    end
  end

  def create
    result = ::Services::Accounts::Create.new.call(create_params.to_h.symbolize_keys, @current_account)

    if result.success?
      render json: ::Presenters::AccountPresenter.render_auth(result.account), status: result.status
    else
      render json: { errors: result.errors, status: Rack::Utils::SYMBOL_TO_STATUS_CODE[result.status] }, status: result.status
    end
  end

  def update
    account = Account.find(params[:id])
    account.update(create_params)

    render json: account
  end

  def destroy
    account = Account.find(params[:id])

    account.destroy

    render json: { message: "deleted" }, status: 200
  end

  private
    def create_params
      params.require(:account).permit(:name, :password, :role, :capacity, area: [])
    end
end
