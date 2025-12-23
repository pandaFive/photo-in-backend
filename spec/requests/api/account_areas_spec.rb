require "rails_helper"

RSpec.describe Api::AccountAreasController, type: :controller do
  describe "POST #create" do
    before do
      @account = create(:account_member)
      @area = create(:area, name: "東京")
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post :create, params: { account_id: @account.id, area_id: @area.id }
        expect(response).to have_http_status(:ok)
      end

      it "アカウントにエリアが紐付けられること" do
        expect {
          post :create, params: { account_id: @account.id, area_id: @area.id }
        }.to change { @account.areas.count }.by(1)
      end

      it "紐付けられたエリア一覧が返ってくること" do
        post :create, params: { account_id: @account.id, area_id: @area.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response[0]["name"]).to eq("東京")
      end
    end

    context "存在しないアカウントの場合" do
      it "Status 500が返ってくること" do
        post :create, params: { account_id: 999999, area_id: @area.id }
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context "存在しないエリアの場合" do
      it "Status 500が返ってくること" do
        post :create, params: { account_id: @account.id, area_id: 999999 }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @account = create(:account_member)
      @area = create(:area, name: "東京")
      @account.add_area(@area)
      @account_area = AccountArea.find_by(account_id: @account.id, area_id: @area.id)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        delete :destroy, params: { id: @account_area.id, account_id: @account.id, area_id: @area.id }
        expect(response).to have_http_status(:ok)
      end

      it "アカウントからエリアが削除されること" do
        expect {
          delete :destroy, params: { id: @account_area.id, account_id: @account.id, area_id: @area.id }
        }.to change { @account.areas.count }.by(-1)
      end

      it "残りのエリア一覧が返ってくること" do
        delete :destroy, params: { id: @account_area.id, account_id: @account.id, area_id: @area.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(0)
      end
    end

    context "存在しないアカウントの場合" do
      it "Status 500が返ってくること" do
        delete :destroy, params: { id: 999999, account_id: 999999, area_id: @area.id }
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context "存在しないエリアの場合" do
      it "Status 500が返ってくること" do
        delete :destroy, params: { id: @account_area.id, account_id: @account.id, area_id: 999999 }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
