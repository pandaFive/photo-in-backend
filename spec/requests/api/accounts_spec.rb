require "rails_helper"

RSpec.describe Api::AccountsController, type: :controller do
  describe "GET #index" do
    context "正しい返り値が返ってくる場合" do
      before do
        @member = create(:account_member)
        create_list(:account_member, 3)
        create_list(:account, 2)
      end

      it "successful が返ってくること" do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "正しい形式のデータが返ってくること" do
        get :index
        expect(response.content_type).to eq("application/json; charset=utf-8")
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[0][:id]).to eq(@member.id)
        expect(json_response[0][:createdAt].to_date).to eq(@member.created_at.to_date)
        expect(json_response[0][:capacity]).to eq(@member.capacity)
        expect(json_response[0][:updatedAt].to_date).to eq(@member.updated_at.to_date)
        expect(json_response[0][:name]).to eq(@member.name)
      end

      it "返ってくるデータの数が正しいこと" do
        get :index
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response.length).to eq(4)
      end
    end
    context "登録されているデータがない場合" do
      before do
        create_list(:account, 2)
      end

      it "successful が返ってくること" do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "データが返って来ないこと" do
        get :index
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response.length).to eq(0)
      end
    end
  end

  describe "GET #show" do
    context "正しい値が返ってくる場合" do
      before do
        @member = create(:account_member)
      end

      it "successful が返ってくること" do
        get :show, params: { id: @member.id }
        expect(response).to have_http_status(:ok)
      end

      it "正しい形式のデータが返ってくること" do
        get :show, params: { id: @member.id }
        expect(response.content_type).to eq("application/json; charset=utf-8")
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:id]).to eq(@member.id)
        expect(json_response[:createdAt].to_date).to eq(@member.created_at.to_date)
        expect(json_response[:capacity]).to eq(@member.capacity)
        expect(json_response[:updatedAt].to_date).to eq(@member.updated_at.to_date)
        expect(json_response[:name]).to eq(@member.name)
      end
    end

    context "データが登録されていない場合" do
      it "internalserver errorが返ってくること" do
        get :show, params: { id: 1 }
        expect(response).to have_http_status(500)
      end
    end
  end

  describe "POST #create" do
    before do
      @area = create(:area)
    end
    context "データが登録される場合" do
      it "登録された情報が返されること" do
        post :create, params: { account: { name: "Test User", password: "password", role: "member", capacity: 2, area: [@area.id] } }
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)["account"]["name"]).to eq("Test User")
      end
    end
    context "データが登録されない場合" do
      it "errorが返されること" do
        # nameが足りない
        post :create, params: { account: { password: "password", role: "member", capacity: 4, area: [@area.id] } }
        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)["status"]).to eq(422)
      end
    end
  end

  describe "PUT #update" do
    before do
      @member = create(:account_member)
      @time = @member.updated_at
    end
    context "更新が成功する場合" do
      it "Status 200が返ってくること" do
        put :update, params: { id: @member.id, account: { name: "更新" } }
        expect(response).to have_http_status(200)
      end
      it "更新されたデータが返ってくること" do
        put :update, params: { id: @member.id, account: { name: "更新" } }
        expect(JSON.parse(response.body)["name"]).to eq("更新")
        expect(JSON.parse(response.body)["updated_at"]).not_to eq(@time)
      end
    end
    context "存在しないaccountのidが指定された場合" do
      it "Status 500が返ってくること" do
        put :update, params: { id: 10, account: { name: "更新" } }
        expect(response).to have_http_status(500)
      end
    end
    context "更新される情報が指定されていない場合" do
      it "Status 500が返ってくること" do
        put :update, params: { id: @member.id }
        expect(response).to have_http_status(500)
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @member = create(:account_member)
    end
    context "アカウントが削除される場合" do
      it "Status 200が返ってくること" do
        delete :destroy, params: { id: @member.id }
        expect(response).to have_http_status(200)
      end
      it "正しいメッセージが返ってくること" do
        delete :destroy, params: { id: @member.id }
        expect(JSON.parse(response.body)["message"]).to eq("deleted")
      end
      it "アカウントが削除されていること" do
        delete :destroy, params: { id: @member.id }
        expect(Account.all.count).to eq(0)
      end
    end
    context "存在しなIDが指定された場合" do
      it "Status 500が返ってくること" do
        delete :destroy, params: { id: 100 }
        expect(response).to have_http_status(500)
      end
    end
  end
end
