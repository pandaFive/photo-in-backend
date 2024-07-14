class Api::AccountsController < ApplicationController
  before_action :authenticated?, only: [:get]
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
    ap = create_params.tap do |whitelisted|
      whitelisted.delete(:area)
    end
    account = Account.new(ap)
    account.capacity = 0 if account.capacity == nil

    account.add_areas(create_params[:area])

    if account.save
      render json: create_render_json(account)
    else
      render json: { message: account.errors, status: 422 }, status: :unprocessable_entity
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
