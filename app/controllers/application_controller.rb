class ApplicationController < ActionController::API
  include JsonWebToken

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
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
      render json: { errors: ["Token has expired"], status: 401 }, status: :unauthorized
    rescue JWT::DecodeError
      render_unauthorized
    end
  end

  private
    # Resultオブジェクトを受け取り、成功/失敗に応じてrenderする
    # @param result [Struct] success?, errors, status を持つResult
    # @yield 成功時のJSONボディを返すブロック
    def render_result(result)
      if result.success?
        render json: yield, status: result.status
      else
        render_error(result.errors, result.status)
      end
    end

    # 統一エラーレスポンス
    # @param errors [Array<String>, String] エラーメッセージ（配列または文字列）
    # @param status [Symbol] HTTPステータスシンボル（:not_found, :forbidden等）
    def render_error(errors, status)
      render json: {
        errors: Array(errors),
        status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
      }, status:
    end

    def render_unauthorized
      render json: { errors: ["unauthorized"], status: 401 }, status: :unauthorized
    end

    def render_not_found(error)
      Rails.logger.warn "Record not found: #{error.message}"
      render json: { errors: ["Resource not found"], status: 404 }, status: :not_found
    end

    def render_bad_request(error)
      Rails.logger.warn "Parameter missing: #{error.message}"
      render json: { errors: ["Bad request"], status: 400 }, status: :bad_request
    end

    def render_standard_error(error)
      # ログにはエラー詳細を記録
      Rails.logger.error "#{error.class}: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")

      # クライアントには詳細を送らない
      render json: { errors: ["Internal server error"], status: 500 }, status: :internal_server_error
    end
end
