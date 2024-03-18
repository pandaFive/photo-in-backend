class Api::TagAccountsController < ApplicationController
  def create
    account = Account.find(params[:account_id])
    tag = Tag.find(params[:tag_id])

    account.add_tag(tag)

    render json: account.tags
  end

  def destroy
    account = Account.find(params[:account_id])
    tag = Tag.find(params[:tag_id])

    account.remove_tag(tag)
    render json: account.tags
  end
end
