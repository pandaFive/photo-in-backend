require "rails_helper"

RSpec.describe Api::AreasController, type: :controller do
  describe "GET #index" do
    before do
      @area1 = create(:area, name: "東京")
      @area2 = create(:area, name: "大阪")
    end

    it "Status 200が返ってくること" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "全てのエリアが返ってくること" do
      get :index
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
    end

    it "正しい形式のデータが返ってくること" do
      get :index
      json_response = JSON.parse(response.body)
      expect(json_response[0]).to have_key("id")
      expect(json_response[0]).to have_key("name")
    end
  end

  describe "GET #show" do
    before do
      @area = create(:area, name: "東京")
    end

    context "存在するエリアの場合" do
      it "Status 200が返ってくること" do
        get :show, params: { id: @area.id }
        expect(response).to have_http_status(:ok)
      end

      it "正しいデータが返ってくること" do
        get :show, params: { id: @area.id }
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(@area.id)
        expect(json_response["name"]).to eq("東京")
      end
    end

    context "存在しないエリアの場合" do
      it "Status 500が返ってくること" do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe "POST #create" do
    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post :create, params: { area: { name: "新規エリア" } }
        expect(response).to have_http_status(:ok)
      end

      it "エリアが作成されること" do
        expect {
          post :create, params: { area: { name: "新規エリア" } }
        }.to change(Area, :count).by(1)
      end

      it "作成されたデータが返ってくること" do
        post :create, params: { area: { name: "新規エリア" } }
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("新規エリア")
      end
    end

    context "無効なパラメータの場合" do
      it "nameが空の場合、Status 422が返ってくること" do
        post :create, params: { area: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "nameが32文字を超える場合、Status 422が返ってくること" do
        post :create, params: { area: { name: "a" * 33 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが返ってくること" do
        post :create, params: { area: { name: "" } }
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("message")
        expect(json_response["status"]).to eq(422)
      end
    end
  end

  describe "PUT #update" do
    before do
      @area = create(:area, name: "元の名前")
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        put :update, params: { id: @area.id, area: { name: "更新後の名前" } }
        expect(response).to have_http_status(:ok)
      end

      it "更新されたデータが返ってくること" do
        put :update, params: { id: @area.id, area: { name: "更新後の名前" } }
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("更新後の名前")
      end

      it "DBが更新されていること" do
        put :update, params: { id: @area.id, area: { name: "更新後の名前" } }
        @area.reload
        expect(@area.name).to eq("更新後の名前")
      end
    end

    context "存在しないエリアの場合" do
      it "Status 500が返ってくること" do
        put :update, params: { id: 999999, area: { name: "更新" } }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @area = create(:area, name: "削除対象")
    end

    context "存在するエリアの場合" do
      it "Status 204が返ってくること" do
        delete :destroy, params: { id: @area.id }
        expect(response).to have_http_status(:no_content)
      end

      it "エリアが削除されること" do
        expect {
          delete :destroy, params: { id: @area.id }
        }.to change(Area, :count).by(-1)
      end
    end

    context "存在しないエリアの場合" do
      it "Status 500が返ってくること" do
        delete :destroy, params: { id: 999999 }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
