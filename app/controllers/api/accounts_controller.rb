class Api::AccountsController < ApplicationController
  before_action :authenticated?, only: [:get, :create, :show, :index]

  def index
    accounts = Account.where(role: "member")

    render json: accounts.get_role_one_status
  end

  def get
    render json: ::Presenters::AccountPresenter.render_account(@current_account), status: :ok
  end

  def show
    validation = ::Contracts::Accounts::Show.call(params.permit(:id).to_h.symbolize_keys)
    unless validation.success?
      render json: { errors: validation.errors, status: 422 }, status: :unprocessable_entity
      return
    end
    policy = ::Policies::AccountPolicy.new(@current_account)
    unless policy.admin_only?
      render_unauthorized
      return
    end

    result = ::Services::Accounts::Show.new.call(validation.value)

    if result.success?
      render json: ::Presenters::AccountPresenter.render_account(result.account), status: result.status
    else
      render json: { errors: result.errors, status: Rack::Utils::SYMBOL_TO_STATUS_CODE[result.status] }, status: result.status
    end
  end

  def create
    validation = ::Contracts::Accounts::Create.call(create_params.to_h.symbolize_keys)
    unless validation.success?
      render json: { errors: validation.errors, status: 422 }, status: :unprocessable_entity
      return
    end

    policy = ::Policies::AccountPolicy.new(@current_account)
    unless policy.admin_only?
      render_unauthorized
      return
    end

    result = ::Services::Accounts::Create.new.call(validation.value)

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
