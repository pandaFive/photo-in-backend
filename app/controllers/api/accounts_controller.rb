class Api::AccountsController < ApplicationController
  before_action :authenticated?, only: [:get, :create, :show, :index, :update, :destroy]

  def index
    result = ::Services::Accounts::Index.new.call(@current_account)
    render_result(result) do
      ::Presenters::AccountPresenter.render_accounts(result.accounts, result.data)
    end
  end

  def get
    render json: ::Presenters::AccountPresenter.render_account(@current_account), status: :ok
  end

  def show
    result = ::Services::Accounts::Show.new.call(params.permit(:id).to_h.symbolize_keys, @current_account)
    render_result(result) do
      ::Presenters::AccountPresenter.render_account(result.account)
    end
  end

  def create
    result = ::Services::Accounts::Create.new.call(create_params.to_h.symbolize_keys, @current_account)
    render_result(result) do
      ::Presenters::AccountPresenter.render_auth(result.account)
    end
  end

  def update
    update_params = create_params.to_h.symbolize_keys.merge(id: params[:id])
    result = ::Services::Accounts::Update.new.call(update_params, @current_account)
    render_result(result) do
      ::Presenters::AccountPresenter.render_account(result.account)
    end
  end

  def destroy
    result = ::Services::Accounts::Destroy.new.call(params.permit(:id).to_h.symbolize_keys, @current_account)
    render_result(result) do
      { message: "deleted" }
    end
  end

  private
    def create_params
      params.require(:account).permit(:name, :password, :role, :capacity, area: [])
    end
end
