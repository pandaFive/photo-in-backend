require "rails_helper"

RSpec.describe Api::AuthenticationsController, type: :controller do
  describe "POST #login" do
    before do
      @account = create(:account_member, name: "testuser", password: "password123")
    end

    context "正しい認証情報でログインする場合" do
      it "Status 200が返ってくること" do
        post :login, params: { account: { name: "testuser", password: "password123" } }
        expect(response).to have_http_status(200)
      end

      it "アカウント情報とトークンが返ってくること" do
        post :login, params: { account: { name: "testuser", password: "password123" } }
        json_response = JSON.parse(response.body, symbolize_names: true)

        expect(json_response).to have_key(:account)
        expect(json_response[:account]).to have_key(:id)
        expect(json_response[:account]).to have_key(:role)
        expect(json_response[:account]).to have_key(:token)
        expect(json_response[:account]).to have_key(:name)
        expect(json_response[:account][:id]).to eq(@account.id)
        expect(json_response[:account][:name]).to eq("testuser")
      end

      it "JWTトークンが含まれていること" do
        post :login, params: { account: { name: "testuser", password: "password123" } }
        json_response = JSON.parse(response.body, symbolize_names: true)

        expect(json_response[:account][:token]).not_to be_nil
        expect(json_response[:account][:token]).to be_a(String)
      end
    end

    context "存在しないユーザー名でログインする場合" do
      it "Status 422が返ってくること" do
        post :login, params: { account: { name: "nonexistent", password: "password123" } }
        expect(response).to have_http_status(422)
      end

      it "エラーレスポンスが返ってくること" do
        post :login, params: { account: { name: "nonexistent", password: "password123" } }
        json_response = JSON.parse(response.body, symbolize_names: true)

        expect(json_response).to have_key(:status)
        expect(json_response[:status]).to eq(402)
      end
    end

    context "間違ったパスワードでログインする場合" do
      it "Status 422が返ってくること" do
        post :login, params: { account: { name: "testuser", password: "wrongpassword" } }
        expect(response).to have_http_status(422)
      end

      it "エラーレスポンスが返ってくること" do
        post :login, params: { account: { name: "testuser", password: "wrongpassword" } }
        json_response = JSON.parse(response.body, symbolize_names: true)

        expect(json_response).to have_key(:status)
        expect(json_response[:status]).to eq(402)
      end
    end

    context "パラメータが不足している場合" do
      it "エラーが発生すること" do
        expect {
          post :login, params: { account: { name: "testuser" } }
        }.to raise_error
      end
    end
  end
end
