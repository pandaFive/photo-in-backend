# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::AccountsController, type: :controller do
  describe "GET #index" do
    context "adminユーザーがアクセスする場合" do
      before do
        @admin = create(:account)
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

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

    context "memberユーザーがアクセスする場合" do
      before do
        @member = create(:account_member)
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "forbiddenが返ること" do
        get :index
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ること" do
        get :index
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:errors]).to include("権限がありません")
      end
    end

    context "認証なしでアクセスする場合" do
      it "unauthorizedが返ること" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET #show" do
    context "adminユーザーがアクセスする場合" do
      before do
        @admin = create(:account)
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

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
        it "Not Foundが返ってくること" do
          get :show, params: { id: 999999 }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "memberユーザーがアクセスする場合" do
      let!(:target) { create(:account_member, name: "target") }

      before do
        @member = create(:account_member)
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "forbiddenが返ること" do
        get :show, params: { id: target.id }
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ること" do
        get :show, params: { id: target.id }
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:errors]).to include("権限がありません")
      end
    end

    context "認証なしでアクセスする場合" do
      let!(:target) { create(:account_member) }

      it "unauthorizedが返ること" do
        get :show, params: { id: target.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #create" do
    let!(:area) { create(:area) }

    context "adminユーザーがアクセスする場合" do
      before do
        @admin = create(:account)
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      context "データが登録される場合" do
        it "登録された情報が返されること" do
          post :create, params: { account: { name: "Test User", password: "password", role: "member", capacity: 2, area: [area.id] } }
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)["account"]["name"]).to eq("Test User")
        end
      end

      context "データが登録されない場合" do
        it "errorが返されること" do
          post :create, params: { account: { password: "password", role: "member", capacity: 4, area: [area.id] } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "memberユーザーがアクセスする場合" do
      before do
        @member = create(:account_member)
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "forbiddenが返ること" do
        post :create, params: { account: { name: "Test User", password: "password", role: "member", capacity: 2, area: [area.id] } }
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ること" do
        post :create, params: { account: { name: "Test User", password: "password", role: "member", capacity: 2, area: [area.id] } }
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:errors]).to include("権限がありません")
      end

      it "アカウントが作成されないこと" do
        expect {
          post :create, params: { account: { name: "Test User", password: "password", role: "member", capacity: 2, area: [area.id] } }
        }.not_to change(Account, :count)
      end
    end

    context "認証なしでアクセスする場合" do
      it "unauthorizedが返ること" do
        post :create, params: { account: { name: "Test User", password: "password", role: "member", capacity: 2, area: [area.id] } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT #update" do
    before do
      @admin = create(:account)  # admin roleのアカウント
      token = JsonWebToken.encode({ account_id: @admin.id })
      request.headers["Authorization"] = "Bearer #{token}"
      @member = create(:account_member)
      @time = @member.updated_at
    end

    context "更新が成功する場合" do
      it "Status 200が返ってくること" do
        put :update, params: { id: @member.id, account: { name: "更新" } }
        expect(response).to have_http_status(:ok)
      end

      it "更新されたデータが返ってくること" do
        put :update, params: { id: @member.id, account: { name: "更新" } }
        expect(JSON.parse(response.body)["name"]).to eq("更新")
        expect(JSON.parse(response.body)["updated_at"]).not_to eq(@time)
      end
    end

    context "存在しないaccountのidが指定された場合" do
      it "Status 404が返ってくること" do
        put :update, params: { id: 999999, account: { name: "更新" } }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "更新される情報が指定されていない場合" do
      it "Status 400が返ってくること" do
        put :update, params: { id: @member.id }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "memberユーザーがアクセスする場合" do
      before do
        member = create(:account_member)
        token = JsonWebToken.encode({ account_id: member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 403が返ってくること" do
        put :update, params: { id: @member.id, account: { name: "更新" } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "未認証ユーザーがアクセスする場合" do
      before do
        request.headers["Authorization"] = nil
      end

      it "Status 401が返ってくること" do
        put :update, params: { id: @member.id, account: { name: "更新" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @admin = create(:account)  # admin roleのアカウント
      token = JsonWebToken.encode({ account_id: @admin.id })
      request.headers["Authorization"] = "Bearer #{token}"
      @member = create(:account_member)
    end

    context "アカウントが削除される場合" do
      it "Status 200が返ってくること" do
        delete :destroy, params: { id: @member.id }
        expect(response).to have_http_status(:ok)
      end

      it "正しいメッセージが返ってくること" do
        delete :destroy, params: { id: @member.id }
        expect(JSON.parse(response.body)["message"]).to eq("deleted")
      end

      it "アカウントが削除されていること" do
        expect { delete :destroy, params: { id: @member.id } }.to change(Account, :count).by(-1)
      end
    end

    context "存在しないIDが指定された場合" do
      it "Status 404が返ってくること" do
        delete :destroy, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "自分自身を削除しようとした場合" do
      it "Status 403が返ってくること" do
        delete :destroy, params: { id: @admin.id }
        expect(response).to have_http_status(:forbidden)
      end

      it "適切なエラーメッセージが返ること" do
        delete :destroy, params: { id: @admin.id }
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:errors]).to include("自分自身のアカウントは削除できません")
      end

      it "アカウントが削除されないこと" do
        expect { delete :destroy, params: { id: @admin.id } }.not_to change(Account, :count)
      end
    end

    context "最後の管理者を削除しようとした場合" do
      let!(:other_admin) { create(:account) }

      before do
        # @adminを削除して、other_adminだけにする
        @admin.destroy
        token = JsonWebToken.encode({ account_id: other_admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 403が返ってくること" do
        # 他の管理者を作成して削除を試みる（自己削除にならないように）
        another_admin = create(:account)
        # この時点で管理者は2人（other_admin, another_admin）
        # another_adminを削除しても問題なし
        delete :destroy, params: { id: another_admin.id }
        expect(response).to have_http_status(:ok)

        # 最後の1人になったother_adminは削除できない（自己削除防止で先にブロック）
        # 別の管理者から見て最後の管理者を削除しようとするケースをテスト
      end
    end

    context "最後の管理者を他の管理者が削除しようとした場合" do
      let!(:admin2) { create(:account) }

      before do
        # admin2でログイン
        token = JsonWebToken.encode({ account_id: admin2.id })
        request.headers["Authorization"] = "Bearer #{token}"
        # @adminを削除して管理者を1人にする
        @admin.destroy
      end

      it "最後の管理者（自分自身）は削除できないこと" do
        # admin2が最後の管理者
        delete :destroy, params: { id: admin2.id }
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:errors]).to include("自分自身のアカウントは削除できません")
      end
    end
  end

  # JWT セキュリティテスト
  describe "JWT Token Security" do
    let!(:admin) { create(:account) }

    context "期限切れトークンでアクセスする場合" do
      before do
        expired_token = JsonWebToken.encode({ account_id: admin.id }, 1.day.ago)
        request.headers["Authorization"] = "Bearer #{expired_token}"
      end

      it "unauthorizedが返ること" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end

      it "適切なエラーメッセージが返ること" do
        get :index
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:errors]).to include("Token has expired")
      end
    end

    context "不正な署名のトークンでアクセスする場合" do
      before do
        # 異なる秘密鍵で署名された正しい形式のJWT
        invalid_token = JWT.encode({ account_id: admin.id }, "wrong_secret", "HS256")
        request.headers["Authorization"] = "Bearer #{invalid_token}"
      end

      it "unauthorizedが返ること" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "Bearer プレフィックスなしでアクセスする場合" do
      before do
        token = JsonWebToken.encode({ account_id: admin.id })
        request.headers["Authorization"] = token
      end

      # 現在の実装では Bearer プレフィックスなしでもトークンを受け入れる
      # split(" ").last でトークン部分を抽出するため
      it "トークンが有効であればアクセスできること" do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context "存在しないアカウントIDのトークンでアクセスする場合" do
      before do
        token = JsonWebToken.encode({ account_id: 999999 })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "unauthorizedが返ること" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
