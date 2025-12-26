# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Tags", type: :request do
  let!(:admin) { create(:account, role: "admin") }
  let!(:member) { create(:account_member) }
  let(:admin_token) { JsonWebToken.encode({ account_id: admin.id }) }
  let(:member_token) { JsonWebToken.encode({ account_id: member.id }) }
  let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:member_headers) { { "Authorization" => "Bearer #{member_token}" } }

  describe "GET /api/tags" do
    before do
      @tag1 = create(:tag, name: "重要")
      @tag2 = create(:tag, name: "緊急")
    end

    context "認証済みユーザーの場合" do
      it "Status 200が返ってくること" do
        get "/api/tags", headers: admin_headers
        expect(response).to have_http_status(:ok)
      end

      it "全てのタグが返ってくること" do
        get "/api/tags", headers: admin_headers
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(2)
      end

      it "正しい形式のデータが返ってくること" do
        get "/api/tags", headers: admin_headers
        json_response = JSON.parse(response.body)
        expect(json_response[0]).to have_key("id")
        expect(json_response[0]).to have_key("name")
      end

      it "memberユーザーでも取得できること" do
        get "/api/tags", headers: member_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        get "/api/tags"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/tags/:id" do
    before do
      @tag = create(:tag, name: "緊急")
    end

    context "認証済みユーザーの場合" do
      context "存在するタグの場合" do
        it "Status 200が返ってくること" do
          get "/api/tags/#{@tag.id}", headers: admin_headers
          expect(response).to have_http_status(:ok)
        end

        it "正しいデータが返ってくること" do
          get "/api/tags/#{@tag.id}", headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["id"]).to eq(@tag.id)
          expect(json_response["name"]).to eq("緊急")
        end

        it "memberユーザーでも取得できること" do
          get "/api/tags/#{@tag.id}", headers: member_headers
          expect(response).to have_http_status(:ok)
        end
      end

      context "存在しないタグの場合" do
        it "Status 404が返ってくること" do
          get "/api/tags/999999", headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end
      end

      context "無効なIDフォーマットの場合" do
        it "文字列IDでStatus 422が返ってくること" do
          get "/api/tags/abc", headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        get "/api/tags/#{@tag.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/tags" do
    context "adminユーザーの場合" do
      context "有効なパラメータの場合" do
        it "Status 201が返ってくること" do
          post "/api/tags", params: { tag: { name: "新規タグ" } }, headers: admin_headers
          expect(response).to have_http_status(:created)
        end

        it "タグが作成されること" do
          expect {
            post "/api/tags", params: { tag: { name: "新規タグ" } }, headers: admin_headers
          }.to change(Tag, :count).by(1)
        end

        it "作成されたデータが返ってくること" do
          post "/api/tags", params: { tag: { name: "新規タグ" } }, headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["name"]).to eq("新規タグ")
        end
      end

      context "無効なパラメータの場合" do
        it "nameが空の場合、Status 422が返ってくること" do
          post "/api/tags", params: { tag: { name: "" } }, headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "nameが32文字を超える場合、Status 422が返ってくること" do
          post "/api/tags", params: { tag: { name: "a" * 33 } }, headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/tags", params: { tag: { name: "" } }, headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("errors")
          expect(json_response["status"]).to eq(422)
        end
      end
    end

    context "memberユーザーの場合" do
      it "Status 403が返ってくること" do
        post "/api/tags", params: { tag: { name: "新規タグ" } }, headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "タグが作成されないこと" do
        expect {
          post "/api/tags", params: { tag: { name: "新規タグ" } }, headers: member_headers
        }.not_to change(Tag, :count)
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        post "/api/tags", params: { tag: { name: "新規タグ" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT /api/tags/:id" do
    before do
      @tag = create(:tag, name: "元の名前")
    end

    context "adminユーザーの場合" do
      context "有効なパラメータの場合" do
        it "Status 200が返ってくること" do
          put "/api/tags/#{@tag.id}", params: { tag: { name: "更新後の名前" } }, headers: admin_headers
          expect(response).to have_http_status(:ok)
        end

        it "更新されたデータが返ってくること" do
          put "/api/tags/#{@tag.id}", params: { tag: { name: "更新後の名前" } }, headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["name"]).to eq("更新後の名前")
        end

        it "DBが更新されていること" do
          put "/api/tags/#{@tag.id}", params: { tag: { name: "更新後の名前" } }, headers: admin_headers
          @tag.reload
          expect(@tag.name).to eq("更新後の名前")
        end
      end

      context "存在しないタグの場合" do
        it "Status 404が返ってくること" do
          put "/api/tags/999999", params: { tag: { name: "更新" } }, headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end
      end

      context "無効なIDフォーマットの場合" do
        it "文字列IDでStatus 422が返ってくること" do
          put "/api/tags/abc", params: { tag: { name: "更新" } }, headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "無効なパラメータの場合" do
        it "nameが32文字を超える場合、Status 422が返ってくること" do
          put "/api/tags/#{@tag.id}", params: { tag: { name: "a" * 33 } }, headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "memberユーザーの場合" do
      it "Status 403が返ってくること" do
        put "/api/tags/#{@tag.id}", params: { tag: { name: "更新後の名前" } }, headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "DBが更新されないこと" do
        put "/api/tags/#{@tag.id}", params: { tag: { name: "更新後の名前" } }, headers: member_headers
        @tag.reload
        expect(@tag.name).to eq("元の名前")
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        put "/api/tags/#{@tag.id}", params: { tag: { name: "更新" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/tags/:id" do
    before do
      @tag = create(:tag, name: "削除対象")
    end

    context "adminユーザーの場合" do
      context "存在するタグの場合" do
        it "Status 200が返ってくること" do
          delete "/api/tags/#{@tag.id}", headers: admin_headers
          expect(response).to have_http_status(:ok)
        end

        it "タグが削除されること" do
          expect {
            delete "/api/tags/#{@tag.id}", headers: admin_headers
          }.to change(Tag, :count).by(-1)
        end

        it "削除メッセージが返ってくること" do
          delete "/api/tags/#{@tag.id}", headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("deleted")
        end
      end

      context "存在しないタグの場合" do
        it "Status 404が返ってくること" do
          delete "/api/tags/999999", headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end
      end

      context "無効なIDフォーマットの場合" do
        it "文字列IDでStatus 422が返ってくること" do
          delete "/api/tags/abc", headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "FK制約違反の場合" do
        before do
          admin.tags << @tag
        end

        it "Status 409が返ってくること" do
          delete "/api/tags/#{@tag.id}", headers: admin_headers
          expect(response).to have_http_status(:conflict)
        end

        it "タグが削除されないこと" do
          expect {
            delete "/api/tags/#{@tag.id}", headers: admin_headers
          }.not_to change(Tag, :count)
        end
      end
    end

    context "memberユーザーの場合" do
      it "Status 403が返ってくること" do
        delete "/api/tags/#{@tag.id}", headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "タグが削除されないこと" do
        expect {
          delete "/api/tags/#{@tag.id}", headers: member_headers
        }.not_to change(Tag, :count)
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        delete "/api/tags/#{@tag.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
