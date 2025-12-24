# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# 許可するオリジンを環境変数で制御（カンマ区切りで複数指定可能）
# 本番環境では必ず明示的なドメインを設定すること
# 例: ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com
allowed_origins = ENV.fetch("ALLOWED_ORIGINS", "http://localhost:3333")
  .split(",")
  .map(&:strip)
  .reject(&:empty?)

# 本番環境では ALLOWED_ORIGINS の明示的な設定を強制
if Rails.env.production? && (allowed_origins.empty? || allowed_origins.include?("http://localhost:3333"))
  raise "ALLOWED_ORIGINS must be explicitly set in production environment (localhost is not allowed)"
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
