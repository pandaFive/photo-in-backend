# frozen_string_literal: true

# Rack::Attack設定
# DoS攻撃・ブルートフォース攻撃対策
class Rack::Attack
  ### スロットリング設定 ###

  # 全リクエスト: 1分あたり300リクエストまで（IPアドレスごと）
  throttle("req/ip", limit: 300, period: 1.minute) do |req|
    req.ip
  end

  # ログインエンドポイント: 1分あたり5回まで（ブルートフォース対策）
  throttle("logins/ip", limit: 5, period: 1.minute) do |req|
    if req.path == "/api/account/login" && req.post?
      req.ip
    end
  end

  # アカウント作成: 1時間あたり10回まで（スパム対策）
  throttle("signups/ip", limit: 10, period: 1.hour) do |req|
    if req.path == "/api/accounts" && req.post?
      req.ip
    end
  end

  ### ブロックリスト ###

  # 環境変数でブロックIPリストを設定可能
  # BLOCKED_IPS="1.2.3.4,5.6.7.8" の形式
  blocklist("block bad IPs") do |req|
    blocked_ips = ENV.fetch("BLOCKED_IPS", "").split(",").map(&:strip)
    blocked_ips.include?(req.ip)
  end

  ### セーフリスト ###

  # ヘルスチェックエンドポイントは制限対象外
  safelist("allow health checks") do |req|
    req.path == "/health"
  end

  # ローカル開発環境は制限対象外（開発効率のため）
  safelist("allow localhost in development") do |req|
    Rails.env.development? && (req.ip == "127.0.0.1" || req.ip == "::1")
  end

  ### レスポンスカスタマイズ ###

  # スロットリング時のレスポンス（429 Too Many Requests）
  self.throttled_responder = lambda do |req|
    retry_after = (req.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ errors: ["リクエストが多すぎます。しばらく待ってから再試行してください。"], status: 429 }.to_json]
    ]
  end

  # ブロックリスト時のレスポンス（403 Forbidden）
  self.blocklisted_responder = lambda do |_req|
    [
      403,
      { "Content-Type" => "application/json" },
      [{ errors: ["アクセスが拒否されました。"], status: 403 }.to_json]
    ]
  end
end

# ログ出力設定
ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn "[Rack::Attack] Throttled: #{req.ip} - #{req.path}"
end

ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn "[Rack::Attack] Blocked: #{req.ip} - #{req.path}"
end
