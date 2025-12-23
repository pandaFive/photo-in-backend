require "rails_helper"

RSpec.describe Api::TagsController, type: :controller do
  describe "GET #index" do
    before do
      @tag1 = create(:tag, name: "重要")
      @tag2 = create(:tag, name: "緊急")
    end

    it "Status 200が返ってくること" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "全てのタグが返ってくること" do
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

  describe "POST #create" do
    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post :create, params: { tag: { name: "新規タグ" } }
        expect(response).to have_http_status(:ok)
      end

      it "タグが作成されること" do
        expect {
          post :create, params: { tag: { name: "新規タグ" } }
        }.to change(Tag, :count).by(1)
      end

      it "作成されたデータが返ってくること" do
        post :create, params: { tag: { name: "新規タグ" } }
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("新規タグ")
      end
    end

    context "無効なパラメータの場合" do
      it "nameが空の場合、Status 422が返ってくること" do
        post :create, params: { tag: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "nameが32文字を超える場合、Status 422が返ってくること" do
        post :create, params: { tag: { name: "a" * 33 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが返ってくること" do
        post :create, params: { tag: { name: "" } }
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("message")
        expect(json_response["status"]).to eq(422)
      end
    end
  end

  describe "PUT #update" do
    before do
      @tag = create(:tag, name: "元の名前")
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        put :update, params: { id: @tag.id, tag: { name: "更新後の名前" } }
        expect(response).to have_http_status(:ok)
      end

      it "更新されたデータが返ってくること" do
        put :update, params: { id: @tag.id, tag: { name: "更新後の名前" } }
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("更新後の名前")
      end

      it "DBが更新されていること" do
        put :update, params: { id: @tag.id, tag: { name: "更新後の名前" } }
        @tag.reload
        expect(@tag.name).to eq("更新後の名前")
      end
    end

    context "存在しないタグの場合" do
      it "Status 500が返ってくること" do
        put :update, params: { id: 999999, tag: { name: "更新" } }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @tag = create(:tag, name: "削除対象")
    end

    context "存在するタグの場合" do
      it "Status 204が返ってくること" do
        delete :destroy, params: { id: @tag.id }
        expect(response).to have_http_status(:no_content)
      end

      it "タグが削除されること" do
        expect {
          delete :destroy, params: { id: @tag.id }
        }.to change(Tag, :count).by(-1)
      end
    end

    context "存在しないタグの場合" do
      it "Status 500が返ってくること" do
        delete :destroy, params: { id: 999999 }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
