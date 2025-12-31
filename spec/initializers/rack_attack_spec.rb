# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  # テスト用にメモリキャッシュストアを設定
  before(:all) do
    @original_cache_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after(:all) do
    Rack::Attack.cache.store = @original_cache_store
  end

  # 各テスト前にキャッシュをクリア
  before do
    Rack::Attack.cache.store.clear
  end

  describe "throttle" do
    describe "req/ip" do
      it "300リクエスト/分以内は許可される" do
        get "/health"
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end

    describe "logins/ip" do
      let(:login_path) { "/api/account/login" }
      let(:login_params) { { name: "test", password: "password" } }

      it "ログインエンドポイントは5回/分まで許可される" do
        5.times do
          post login_path, params: login_params
        end
        # 5回までは429にならない（認証失敗の401は別）
        expect(response).not_to have_http_status(:too_many_requests)
      end

      it "ログインエンドポイントは6回目でthrottleされる" do
        6.times do
          post login_path, params: login_params
        end
        expect(response).to have_http_status(:too_many_requests)
      end

      it "throttle時にRetry-Afterヘッダーが返される" do
        6.times do
          post login_path, params: login_params
        end
        expect(response.headers["Retry-After"]).to be_present
      end

      it "throttle時にJSONエラーレスポンスが返される" do
        6.times do
          post login_path, params: login_params
        end
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
        expect(json["status"]).to eq(429)
      end
    end

    describe "signups/ip" do
      let(:admin) { create(:account, role: "admin") }
      let(:token) { JsonWebToken.encode(account_id: admin.id) }
      let(:headers) { { "Authorization" => "Bearer #{token}" } }
      let(:signup_path) { "/api/accounts" }
      let(:signup_params) { { account: { name: "newuser", password: "password123", role: "member" } } }

      it "アカウント作成は10回/時まで許可される" do
        10.times do |i|
          post signup_path, params: { account: { name: "user#{i}", password: "password123", role: "member" } }, headers:
        end
        expect(response).not_to have_http_status(:too_many_requests)
      end

      it "アカウント作成は11回目でthrottleされる" do
        11.times do |i|
          post signup_path, params: { account: { name: "user#{i}", password: "password123", role: "member" } }, headers:
        end
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  describe "blocklist" do
    context "BLOCKED_IPSが設定されていない場合" do
      before do
        allow(ENV).to receive(:fetch).with("BLOCKED_IPS", "").and_return("")
      end

      it "リクエストは許可される" do
        get "/health"
        expect(response).not_to have_http_status(:forbidden)
      end
    end
  end

  describe "safelist" do
    it "ヘルスチェックエンドポイントはthrottle対象外" do
      # 大量リクエストを送信してもthrottleされない
      100.times { get "/health" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "レスポンス形式" do
    let(:login_path) { "/api/account/login" }
    let(:login_params) { { name: "test", password: "password" } }

    it "throttle時のレスポンスはJSON形式" do
      6.times { post login_path, params: login_params }
      expect(response.content_type).to include("application/json")
    end
  end
end

RSpec.describe "BLOCKED_IPS環境変数の解析" do
  describe "IPアドレス形式の検証" do
    it "有効なIPv4アドレスを認識する" do
      expect("192.168.1.1").to match(/\A(?:\d{1,3}\.){3}\d{1,3}\z/)
    end

    it "有効なIPv6アドレスを認識する" do
      expect("::1").to match(/\A[a-fA-F0-9:]+\z/)
      expect("2001:db8::1").to match(/\A[a-fA-F0-9:]+\z/)
    end

    it "不正な形式は認識しない" do
      expect("not-an-ip").not_to match(/\A(?:\d{1,3}\.){3}\d{1,3}\z/)
      expect("not-an-ip").not_to match(/\A[a-fA-F0-9:]+\z/)
    end
  end
end
