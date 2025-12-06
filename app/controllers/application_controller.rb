class ApplicationController < ActionController::API
  include JsonWebToken

  rescue_from StandardError, with: :render_standard_error
  # before_action :authenticated?

  def authenticated?
    token = request.headers["Authorization"]
    token = token.chomp.split(" ").last if token

    begin
      @decoded = JsonWebToken.decode(token)
      @current_account = Account.find(@decoded["account_id"])
    rescue ActiveRecord::RecordNotFound
      render_unauthorized
    rescue JWT::ExpiredSignature
      render json: { error: "Token has expired", status: 401 }, status: :unauthorized
    rescue JWT::DecodeError
      render_unauthorized
    end
  end

  private
    def render_unauthorized
      render json: { error: "unauthorized", status: 401 }, status: :unauthorized
    end

    def create_render_json(account)
      token = JsonWebToken.encode({ account_id: account[:id] })
      response = { account: { id: account[:id], role: account[:role], token:, name: account[:name] } }
      response
    end

    def render_standard_error(error)
      # ログにはエラー詳細を記録
      Rails.logger.error "#{error.class}: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")

      # クライアントには詳細を送らない
      render json: { error: "Internal server error" }, status: :internal_server_error
    end
end
