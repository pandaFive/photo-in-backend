# frozen_string_literal: true

require "jwt"

module JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base.to_s
  class << self
    def encode(payload, exp = 24.hours.from_now)
      # 有効期限を追加
      payload[:exp] = exp.to_i
      token = JWT.encode(payload, SECRET_KEY)
      token
    end

    def decode(token)
      # 有効期限の検証を有効化
      decoded = JWT.decode(token, SECRET_KEY, true, { verify_expiration: true })[0]
      decoded
    end
  end
end
