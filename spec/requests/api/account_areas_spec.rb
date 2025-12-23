require "rails_helper"

RSpec.describe "Api::AccountAreas", type: :request do
  describe "POST /api/account_areas" do
    before do
      @account = create(:account_member)
      @area = create(:area, name: "東京")
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post "/api/account_areas", params: { account_id: @account.id, area_id: @area.id }
        expect(response).to have_http_status(:ok)
      end

      it "アカウントにエリアが紐付けられること" do
        expect {
          post "/api/account_areas", params: { account_id: @account.id, area_id: @area.id }
        }.to change { @account.areas.count }.by(1)
      end

      it "紐付けられたエリア一覧が返ってくること" do
        post "/api/account_areas", params: { account_id: @account.id, area_id: @area.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response[0]["name"]).to eq("東京")
      end
    end

    context "存在しないアカウントの場合" do
      it "Status 404が返ってくること" do
        post "/api/account_areas", params: { account_id: 999999, area_id: @area.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "存在しないエリアの場合" do
      it "Status 404が返ってくること" do
        post "/api/account_areas", params: { account_id: @account.id, area_id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/account_areas/:id" do
    before do
      @account = create(:account_member)
      @area = create(:area, name: "東京")
      @account.add_area(@area)
      @account_area = AccountArea.find_by(account_id: @account.id, area_id: @area.id)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        delete "/api/account_areas/#{@account_area.id}", params: { account_id: @account.id, area_id: @area.id }
        expect(response).to have_http_status(:ok)
      end

      it "アカウントからエリアが削除されること" do
        expect {
          delete "/api/account_areas/#{@account_area.id}", params: { account_id: @account.id, area_id: @area.id }
        }.to change { @account.areas.count }.by(-1)
      end

      it "残りのエリア一覧が返ってくること" do
        delete "/api/account_areas/#{@account_area.id}", params: { account_id: @account.id, area_id: @area.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(0)
      end
    end

    context "存在しないアカウントの場合" do
      it "Status 404が返ってくること" do
        delete "/api/account_areas/999999", params: { account_id: 999999, area_id: @area.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "存在しないエリアの場合" do
      it "Status 404が返ってくること" do
        delete "/api/account_areas/#{@account_area.id}", params: { account_id: @account.id, area_id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
