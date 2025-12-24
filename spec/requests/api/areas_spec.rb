# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Areas", type: :request do
  describe "GET /api/areas" do
    before do
      @area1 = create(:area, name: "東京")
      @area2 = create(:area, name: "大阪")
    end

    it "Status 200が返ってくること" do
      get "/api/areas"
      expect(response).to have_http_status(:ok)
    end

    it "全てのエリアが返ってくること" do
      get "/api/areas"
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
    end

    it "正しい形式のデータが返ってくること" do
      get "/api/areas"
      json_response = JSON.parse(response.body)
      expect(json_response[0]).to have_key("id")
      expect(json_response[0]).to have_key("name")
    end
  end

  describe "GET /api/areas/:id" do
    before do
      @area = create(:area, name: "東京")
    end

    context "存在するエリアの場合" do
      it "Status 200が返ってくること" do
        get "/api/areas/#{@area.id}"
        expect(response).to have_http_status(:ok)
      end

      it "正しいデータが返ってくること" do
        get "/api/areas/#{@area.id}"
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(@area.id)
        expect(json_response["name"]).to eq("東京")
      end
    end

    context "存在しないエリアの場合" do
      it "Status 404が返ってくること" do
        get "/api/areas/999999"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/areas" do
    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post "/api/areas", params: { area: { name: "新規エリア" } }
        expect(response).to have_http_status(:ok)
      end

      it "エリアが作成されること" do
        expect {
          post "/api/areas", params: { area: { name: "新規エリア" } }
        }.to change(Area, :count).by(1)
      end

      it "作成されたデータが返ってくること" do
        post "/api/areas", params: { area: { name: "新規エリア" } }
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("新規エリア")
      end
    end

    context "無効なパラメータの場合" do
      it "nameが空の場合、Status 422が返ってくること" do
        post "/api/areas", params: { area: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "nameが32文字を超える場合、Status 422が返ってくること" do
        post "/api/areas", params: { area: { name: "a" * 33 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが返ってくること" do
        post "/api/areas", params: { area: { name: "" } }
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("message")
        expect(json_response["status"]).to eq(422)
      end
    end
  end

  describe "PUT /api/areas/:id" do
    before do
      @area = create(:area, name: "元の名前")
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        put "/api/areas/#{@area.id}", params: { area: { name: "更新後の名前" } }
        expect(response).to have_http_status(:ok)
      end

      it "更新されたデータが返ってくること" do
        put "/api/areas/#{@area.id}", params: { area: { name: "更新後の名前" } }
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("更新後の名前")
      end

      it "DBが更新されていること" do
        put "/api/areas/#{@area.id}", params: { area: { name: "更新後の名前" } }
        @area.reload
        expect(@area.name).to eq("更新後の名前")
      end
    end

    context "存在しないエリアの場合" do
      it "Status 404が返ってくること" do
        put "/api/areas/999999", params: { area: { name: "更新" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/areas/:id" do
    before do
      @area = create(:area, name: "削除対象")
    end

    context "存在するエリアの場合" do
      it "Status 204が返ってくること" do
        delete "/api/areas/#{@area.id}"
        expect(response).to have_http_status(:no_content)
      end

      it "エリアが削除されること" do
        expect {
          delete "/api/areas/#{@area.id}"
        }.to change(Area, :count).by(-1)
      end
    end

    context "存在しないエリアの場合" do
      it "Status 404が返ってくること" do
        delete "/api/areas/999999"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
