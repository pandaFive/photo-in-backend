# frozen_string_literal: true

class Api::TagAccountsController < ApplicationController
  before_action :authenticated?

  # POST /api/tag_accounts
  # アカウントにタグを追加
  def create
    result = ::Services::TagAccounts::Create.new.call(create_params, @current_account)
    render_result(result) do
      ::Presenters::TagPresenter.render_tags(result.tags)
    end
  end

  # DELETE /api/tag_accounts/:id
  # アカウントからタグを削除
  def destroy
    result = ::Services::TagAccounts::Destroy.new.call(destroy_params, @current_account)
    render_result(result) do
      ::Presenters::TagPresenter.render_tags(result.tags)
    end
  end

  private
    def create_params
      params.permit(:account_id, :tag_id).to_h.symbolize_keys
    end

    def destroy_params
      params.permit(:account_id, :tag_id).to_h.symbolize_keys
    end
end
