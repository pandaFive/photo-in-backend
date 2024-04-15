require "jwt"

module JsonWebToken
  SECRET_KEY = Rails.application.secrets.secret_key_base.to_s
  class << self
    def encode(payload)
      token = JWT.encode(payload, SECRET_KEY)
      token
    end

    def decode(token)
      decoded = JWT.decode(token, SECRET_KEY)[0]
      decoded
    end
  end
end
