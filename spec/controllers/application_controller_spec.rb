# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  # テスト用のResult構造体
  TestResult = Struct.new(:success?, :data, :errors, :status, keyword_init: true)

  # 匿名コントローラでrender_result/render_errorをテスト
  controller do
    def success_action
      result = TestResult.new(success?: true, data: { id: 1, name: "test" }, errors: [], status: :ok)
      render_result(result) { result.data }
    end

    def failure_action
      result = TestResult.new(success?: false, data: nil, errors: ["エラー1", "エラー2"], status: :unprocessable_entity)
      render_result(result) { result.data }
    end

    def forbidden_action
      result = TestResult.new(success?: false, data: nil, errors: ["権限がありません"], status: :forbidden)
      render_result(result) { result.data }
    end

    def not_found_action
      result = TestResult.new(success?: false, data: nil, errors: ["リソースが見つかりません"], status: :not_found)
      render_result(result) { result.data }
    end

    def direct_error_action
      render_error(["直接エラー"], :bad_request)
    end

    def single_error_action
      render_error("単一エラー", :unprocessable_entity)
    end
  end

  before do
    # 匿名コントローラ用のルートを追加
    routes.draw do
      get "success_action" => "anonymous#success_action"
      get "failure_action" => "anonymous#failure_action"
      get "forbidden_action" => "anonymous#forbidden_action"
      get "not_found_action" => "anonymous#not_found_action"
      get "direct_error_action" => "anonymous#direct_error_action"
      get "single_error_action" => "anonymous#single_error_action"
    end
  end

  describe "#render_result" do
    context "成功時" do
      it "ブロックの戻り値をJSONとして返すこと" do
        get :success_action
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:id]).to eq(1)
        expect(json[:name]).to eq("test")
      end
    end

    context "失敗時（422 Unprocessable Entity）" do
      it "統一エラーレスポンス形式で返すこと" do
        get :failure_action
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:errors]).to eq(["エラー1", "エラー2"])
        expect(json[:status]).to eq(422)
      end
    end

    context "失敗時（403 Forbidden）" do
      it "統一エラーレスポンス形式で返すこと" do
        get :forbidden_action
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:errors]).to eq(["権限がありません"])
        expect(json[:status]).to eq(403)
      end
    end

    context "失敗時（404 Not Found）" do
      it "統一エラーレスポンス形式で返すこと" do
        get :not_found_action
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:errors]).to eq(["リソースが見つかりません"])
        expect(json[:status]).to eq(404)
      end
    end
  end

  describe "#render_error" do
    context "配列でエラーを渡した場合" do
      it "そのまま配列として返すこと" do
        get :direct_error_action
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:errors]).to eq(["直接エラー"])
        expect(json[:status]).to eq(400)
      end
    end

    context "単一文字列でエラーを渡した場合" do
      it "配列に変換して返すこと" do
        get :single_error_action
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:errors]).to eq(["単一エラー"])
        expect(json[:status]).to eq(422)
      end
    end
  end

  describe "#render_unauthorized" do
    controller do
      def unauthorized_action
        render_unauthorized
      end
    end

    before do
      routes.draw { get "unauthorized_action" => "anonymous#unauthorized_action" }
    end

    it "errors配列形式で401を返すこと" do
      get :unauthorized_action
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors]).to eq(["unauthorized"])
      expect(json[:status]).to eq(401)
    end
  end

  describe "JWT認証エラー" do
    controller do
      before_action :authenticated?

      def protected_action
        render json: { message: "success" }
      end
    end

    before do
      routes.draw { get "protected_action" => "anonymous#protected_action" }
    end

    context "トークンが期限切れの場合" do
      it "errors配列形式で401を返すこと" do
        # 期限切れトークンを生成（JsonWebTokenと同じシークレットキーを使用）
        expired_token = JWT.encode(
          { account_id: 1, exp: 1.day.ago.to_i },
          Rails.application.secret_key_base.to_s
        )
        request.headers["Authorization"] = "Bearer #{expired_token}"

        get :protected_action
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:errors]).to eq(["Token has expired"])
        expect(json[:status]).to eq(401)
      end
    end

    context "トークンが無効な場合" do
      it "errors配列形式で401を返すこと" do
        request.headers["Authorization"] = "Bearer invalid_token"

        get :protected_action
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:errors]).to eq(["unauthorized"])
        expect(json[:status]).to eq(401)
      end
    end
  end

  describe "#render_standard_error" do
    controller do
      def error_action
        raise StandardError, "Something went wrong"
      end
    end

    before do
      routes.draw { get "error_action" => "anonymous#error_action" }
    end

    it "errors配列形式で500を返すこと" do
      get :error_action
      expect(response).to have_http_status(:internal_server_error)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors]).to eq(["Internal server error"])
      expect(json[:status]).to eq(500)
    end
  end
end
