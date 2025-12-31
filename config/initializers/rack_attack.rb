# frozen_string_literal: true

# Rack::Attack設定
# DoS攻撃・ブルートフォース攻撃対策
#
# 本番環境での注意事項:
# - ECS Fargate等の複数コンテナ環境では、Redisキャッシュストアの設定が必要
# - 設定例: Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])
# - デフォルトのファイルストアでは、コンテナ間でカウントが共有されない

begin
  # ブロックIPリストの初期化（起動時に一度だけパース）
  BLOCKED_IPS = begin
    raw_ips = ENV.fetch("BLOCKED_IPS", "")
    if raw_ips.blank?
      []
    else
      ips = raw_ips.split(",").map(&:strip).reject(&:blank?)

      # IPアドレス形式の検証（IPv4, IPv6）
      valid_ips = []
      invalid_ips = []

      ips.each do |ip|
        if ip.match?(/\A(?:\d{1,3}\.){3}\d{1,3}\z/) || ip.match?(/\A[a-fA-F0-9:]+\z/)
          valid_ips << ip
        else
          invalid_ips << ip
        end
      end

      if invalid_ips.any?
        Rails.logger.error "[Rack::Attack] 不正なIP形式が含まれています: #{invalid_ips.join(', ')}"
      end

      if valid_ips.any?
        Rails.logger.info "[Rack::Attack] ブロックリスト初期化: #{valid_ips.size}件のIP"
      end

      valid_ips
    end
  end.freeze

  # クライアントIPを安全に取得するヘルパー
  # ALB/プロキシ経由の場合はX-Forwarded-Forを考慮
  def self.get_client_ip(req)
    req.env["action_dispatch.remote_ip"]&.to_s || req.ip
  rescue StandardError
    req.ip
  end

  class Rack::Attack
    ### スロットリング設定 ###

    # 全リクエスト: 1分あたり300リクエストまで（IPアドレスごと）
    # 通常のブラウジングでは60-100req/min程度を想定
    throttle("req/ip", limit: 300, period: 1.minute) do |req|
      req.env["action_dispatch.remote_ip"]&.to_s || req.ip
    rescue StandardError => e
      Rails.logger.error "[Rack::Attack] req/ip IP取得エラー: #{e.class}"
      nil
    end

    # ログインエンドポイント: 1分あたり5回まで（ブルートフォース対策）
    throttle("logins/ip", limit: 5, period: 1.minute) do |req|
      if req.path == "/api/account/login" && req.post?
        req.env["action_dispatch.remote_ip"]&.to_s || req.ip
      end
    rescue StandardError => e
      Rails.logger.error "[Rack::Attack] logins/ip エラー: #{e.class}"
      nil
    end

    # アカウント作成: 1時間あたり10回まで（管理者操作の過負荷防止）
    throttle("signups/ip", limit: 10, period: 1.hour) do |req|
      if req.path == "/api/accounts" && req.post?
        req.env["action_dispatch.remote_ip"]&.to_s || req.ip
      end
    rescue StandardError => e
      Rails.logger.error "[Rack::Attack] signups/ip エラー: #{e.class}"
      nil
    end

    ### ブロックリスト ###

    # 環境変数でブロックIPリストを設定可能
    # BLOCKED_IPS="1.2.3.4,5.6.7.8" の形式
    blocklist("block bad IPs") do |req|
      client_ip = req.env["action_dispatch.remote_ip"]&.to_s || req.ip
      BLOCKED_IPS.include?(client_ip)
    rescue StandardError => e
      Rails.logger.error "[Rack::Attack] blocklist エラー: #{e.class}"
      false
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
    # Retry-Afterヘッダーで制限解除までの秒数を通知
    self.throttled_responder = lambda do |req|
      match_data = req.env["rack.attack.match_data"]
      retry_after = match_data&.dig(:period) || 60

      [
        429,
        {
          "Content-Type" => "application/json",
          "Retry-After" => retry_after.to_s
        },
        [{ errors: ["リクエストが多すぎます。#{retry_after}秒後に再試行してください。"], status: 429 }.to_json]
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

  # セキュリティイベントのログ出力設定
  # スロットリング・ブロック発生時にWARNレベルで記録
  # 注意: IPアドレスはセキュリティ監視目的で記録（GDPR考慮が必要な場合はマスキング検討）
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    if req
      client_ip = req.env["action_dispatch.remote_ip"]&.to_s || req.ip
      Rails.logger.warn "[Rack::Attack] Throttled: #{client_ip} - #{req.path}"
    else
      Rails.logger.warn "[Rack::Attack] Throttled: (リクエスト情報取得不可)"
    end
  rescue StandardError => e
    Rails.logger.error "[Rack::Attack] Throttleログ出力エラー: #{e.class}"
  end

  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    if req
      client_ip = req.env["action_dispatch.remote_ip"]&.to_s || req.ip
      Rails.logger.warn "[Rack::Attack] Blocked: #{client_ip} - #{req.path}"
    else
      Rails.logger.warn "[Rack::Attack] Blocked: (リクエスト情報取得不可)"
    end
  rescue StandardError => e
    Rails.logger.error "[Rack::Attack] Blockログ出力エラー: #{e.class}"
  end

  Rails.logger.info "[Rack::Attack] 初期化完了"

rescue NameError => e
  Rails.logger.error "[Rack::Attack] Rack::Attackが利用できません: #{e.message}"
  raise if Rails.env.production?
rescue StandardError => e
  Rails.logger.error "[Rack::Attack] 初期化に失敗しました: #{e.class} - #{e.message}"
  raise if Rails.env.production?
end
