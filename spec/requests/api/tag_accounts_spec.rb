require "rails_helper"

RSpec.describe "Api::TagAccounts", type: :request do
  describe "POST /api/tag_accounts" do
    before do
      @account = create(:account_member)
      @tag = create(:tag, name: "重要")
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post "/api/tag_accounts", params: { account_id: @account.id, tag_id: @tag.id }
        expect(response).to have_http_status(:ok)
      end

      it "アカウントにタグが紐付けられること" do
        expect {
          post "/api/tag_accounts", params: { account_id: @account.id, tag_id: @tag.id }
        }.to change { @account.tags.count }.by(1)
      end

      it "紐付けられたタグ一覧が返ってくること" do
        post "/api/tag_accounts", params: { account_id: @account.id, tag_id: @tag.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response[0]["name"]).to eq("重要")
      end
    end

    context "存在しないアカウントの場合" do
      it "Status 404が返ってくること" do
        post "/api/tag_accounts", params: { account_id: 999999, tag_id: @tag.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "存在しないタグの場合" do
      it "Status 404が返ってくること" do
        post "/api/tag_accounts", params: { account_id: @account.id, tag_id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/tag_accounts/:id" do
    before do
      @account = create(:account_member)
      @tag = create(:tag, name: "重要")
      @account.add_tag(@tag)
      @tag_account = TagAccount.find_by(account_id: @account.id, tag_id: @tag.id)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        delete "/api/tag_accounts/#{@tag_account.id}", params: { account_id: @account.id, tag_id: @tag.id }
        expect(response).to have_http_status(:ok)
      end

      it "アカウントからタグが削除されること" do
        expect {
          delete "/api/tag_accounts/#{@tag_account.id}", params: { account_id: @account.id, tag_id: @tag.id }
        }.to change { @account.tags.count }.by(-1)
      end

      it "残りのタグ一覧が返ってくること" do
        delete "/api/tag_accounts/#{@tag_account.id}", params: { account_id: @account.id, tag_id: @tag.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(0)
      end
    end

    context "存在しないアカウントの場合" do
      it "Status 404が返ってくること" do
        delete "/api/tag_accounts/999999", params: { account_id: 999999, tag_id: @tag.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "存在しないタグの場合" do
      it "Status 404が返ってくること" do
        delete "/api/tag_accounts/#{@tag_account.id}", params: { account_id: @account.id, tag_id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
