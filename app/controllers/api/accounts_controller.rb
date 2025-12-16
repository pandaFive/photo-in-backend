class Api::AccountsController < ApplicationController
  before_action :authenticated?, only: [:get, :create]
  def index
    accounts = Account.where(role: "member")

    render json: accounts.get_role_one_status
  end

  def get
    render json: create_render_json(@current_account)
  end

  def show
    account = Account.find(params[:id])

    render json: account.get_status
  end

  def create
    validation = Validators::Accounts::Create.call(create_params.to_h.symbolize_keys)
    unless validation.success?
      render json: { errors: validation.errors, status: 422 }, status: :unprocessable_entity
      return
    end

    policy = AccountPolicy.new(@current_account)
    unless policy.create?
      render_unauthorized
      return
    end

    result = Accounts::Create.new.call(validation.value)

    if result.success?
      render json: AccountPresenter.render_auth(result.account), status: result.status
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
