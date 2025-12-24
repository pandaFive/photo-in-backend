# frozen_string_literal: true

class Api::AuthenticationsController < ApplicationController
  def login
    result = ::Services::Authentications::Login.new.call(login_params.to_h.symbolize_keys)
    render_result(result) do
      ::Presenters::AccountPresenter.render_auth(result.account)
    end
  end

  private
    def login_params
      params.require(:account).permit(:name, :password)
    end
end
