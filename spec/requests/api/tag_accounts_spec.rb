require "rails_helper"

RSpec.describe Api::TagAccountsController, type: :controller do
  describe "POST #create" do
    before do
      @account = create(:account_member)
      @tag = create(:tag, name: "重要")
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post :create, params: { account_id: @account.id, tag_id: @tag.id }
        expect(response).to have_http_status(:ok)
      end

      it "アカウントにタグが紐付けられること" do
        expect {
          post :create, params: { account_id: @account.id, tag_id: @tag.id }
        }.to change { @account.tags.count }.by(1)
      end

      it "紐付けられたタグ一覧が返ってくること" do
        post :create, params: { account_id: @account.id, tag_id: @tag.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response[0]["name"]).to eq("重要")
      end
    end

    context "存在しないアカウントの場合" do
      it "Status 500が返ってくること" do
        post :create, params: { account_id: 999999, tag_id: @tag.id }
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context "存在しないタグの場合" do
      it "Status 500が返ってくること" do
        post :create, params: { account_id: @account.id, tag_id: 999999 }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @account = create(:account_member)
      @tag = create(:tag, name: "重要")
      @account.add_tag(@tag)
      @tag_account = TagAccount.find_by(account_id: @account.id, tag_id: @tag.id)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        delete :destroy, params: { id: @tag_account.id, account_id: @account.id, tag_id: @tag.id }
        expect(response).to have_http_status(:ok)
      end

      it "アカウントからタグが削除されること" do
        expect {
          delete :destroy, params: { id: @tag_account.id, account_id: @account.id, tag_id: @tag.id }
        }.to change { @account.tags.count }.by(-1)
      end

      it "残りのタグ一覧が返ってくること" do
        delete :destroy, params: { id: @tag_account.id, account_id: @account.id, tag_id: @tag.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(0)
      end
    end

    context "存在しないアカウントの場合" do
      it "Status 500が返ってくること" do
        delete :destroy, params: { id: 999999, account_id: 999999, tag_id: @tag.id }
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context "存在しないタグの場合" do
      it "Status 500が返ってくること" do
        delete :destroy, params: { id: @tag_account.id, account_id: @account.id, tag_id: 999999 }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
