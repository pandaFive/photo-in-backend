# frozen_string_literal: true

require "jwt"

module JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base.to_s
  # アルゴリズム混乱攻撃を防ぐため、アルゴリズムを明示的に指定
  ALGORITHM = "HS256"

  class << self
    def encode(payload, exp = 24.hours.from_now)
      # 有効期限を追加
      payload[:exp] = exp.to_i
      token = JWT.encode(payload, SECRET_KEY, ALGORITHM)
      token
    end

    def decode(token)
      # 有効期限の検証を有効化、アルゴリズムを明示的に指定
      decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM, verify_expiration: true })[0]
      decoded
    end
  end
end
