# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::AccountAreas", type: :request do
  let!(:admin) { create(:account, role: "admin") }
  let!(:member) { create(:account_member) }
  let(:admin_token) { JsonWebToken.encode({ account_id: admin.id }) }
  let(:member_token) { JsonWebToken.encode({ account_id: member.id }) }
  let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:member_headers) { { "Authorization" => "Bearer #{member_token}" } }

  describe "POST /api/account_areas" do
    let!(:target_account) { create(:account_member) }
    let!(:area) { create(:area, name: "東京") }

    context "認証済みadminユーザーの場合" do
      context "有効なパラメータの場合" do
        it "Status 200が返ってくること" do
          post "/api/account_areas",
            params: { account_id: target_account.id, area_id: area.id },
            headers: admin_headers
          expect(response).to have_http_status(:ok)
        end

        it "アカウントにエリアが紐付けられること" do
          expect {
            post "/api/account_areas",
              params: { account_id: target_account.id, area_id: area.id },
              headers: admin_headers
          }.to change { target_account.areas.count }.by(1)
        end

        it "紐付けられたエリア一覧が返ってくること" do
          post "/api/account_areas",
            params: { account_id: target_account.id, area_id: area.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response.length).to eq(1)
          expect(json_response[0]["name"]).to eq("東京")
        end
      end

      context "既にエリアが追加されている場合" do
        before do
          target_account.areas << area
        end

        it "Status 409が返ってくること" do
          post "/api/account_areas",
            params: { account_id: target_account.id, area_id: area.id },
            headers: admin_headers
          expect(response).to have_http_status(:conflict)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/account_areas",
            params: { account_id: target_account.id, area_id: area.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("このエリアは既に追加されています")
        end
      end

      context "存在しないアカウントの場合" do
        it "Status 404が返ってくること" do
          post "/api/account_areas",
            params: { account_id: 999999, area_id: area.id },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/account_areas",
            params: { account_id: 999999, area_id: area.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("アカウントが見つかりません")
        end
      end

      context "存在しないエリアの場合" do
        it "Status 404が返ってくること" do
          post "/api/account_areas",
            params: { account_id: target_account.id, area_id: 999999 },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/account_areas",
            params: { account_id: target_account.id, area_id: 999999 },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("エリアが見つかりません")
        end
      end

      context "account_idがない場合" do
        it "Status 422が返ってくること" do
          post "/api/account_areas",
            params: { area_id: area.id },
            headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "area_idがない場合" do
        it "Status 422が返ってくること" do
          post "/api/account_areas",
            params: { account_id: target_account.id },
            headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "認証済みmemberユーザーの場合" do
      it "Status 403が返ってくること" do
        post "/api/account_areas",
          params: { account_id: target_account.id, area_id: area.id },
          headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ってくること" do
        post "/api/account_areas",
          params: { account_id: target_account.id, area_id: area.id },
          headers: member_headers
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end

      it "エリアが追加されないこと" do
        expect {
          post "/api/account_areas",
            params: { account_id: target_account.id, area_id: area.id },
            headers: member_headers
        }.not_to change { target_account.areas.count }
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        post "/api/account_areas",
          params: { account_id: target_account.id, area_id: area.id }
        expect(response).to have_http_status(:unauthorized)
      end

      it "エリアが追加されないこと" do
        expect {
          post "/api/account_areas",
            params: { account_id: target_account.id, area_id: area.id }
        }.not_to change { target_account.areas.count }
      end
    end
  end

  describe "DELETE /api/account_areas/:id" do
    let!(:target_account) { create(:account_member) }
    let!(:area) { create(:area, name: "東京") }

    before do
      target_account.add_area(area)
      @account_area = AccountArea.find_by(account_id: target_account.id, area_id: area.id)
    end

    context "認証済みadminユーザーの場合" do
      context "有効なパラメータの場合" do
        it "Status 200が返ってくること" do
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: target_account.id, area_id: area.id },
            headers: admin_headers
          expect(response).to have_http_status(:ok)
        end

        it "アカウントからエリアが削除されること" do
          expect {
            delete "/api/account_areas/#{@account_area.id}",
              params: { account_id: target_account.id, area_id: area.id },
              headers: admin_headers
          }.to change { target_account.areas.count }.by(-1)
        end

        it "残りのエリア一覧が返ってくること" do
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: target_account.id, area_id: area.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response.length).to eq(0)
        end
      end

      context "存在しないアカウントの場合" do
        it "Status 404が返ってくること" do
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: 999999, area_id: area.id },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: 999999, area_id: area.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("アカウントが見つかりません")
        end
      end

      context "存在しないエリアの場合" do
        it "Status 404が返ってくること" do
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: target_account.id, area_id: 999999 },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: target_account.id, area_id: 999999 },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("エリアが見つかりません")
        end
      end

      context "紐付いていないエリアの場合" do
        let!(:other_area) { create(:area, name: "大阪") }

        it "Status 404が返ってくること" do
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: target_account.id, area_id: other_area.id },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: target_account.id, area_id: other_area.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("このエリアはアカウントに紐付いていません")
        end
      end
    end

    context "認証済みmemberユーザーの場合" do
      it "Status 403が返ってくること" do
        delete "/api/account_areas/#{@account_area.id}",
          params: { account_id: target_account.id, area_id: area.id },
          headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ってくること" do
        delete "/api/account_areas/#{@account_area.id}",
          params: { account_id: target_account.id, area_id: area.id },
          headers: member_headers
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end

      it "エリアが削除されないこと" do
        expect {
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: target_account.id, area_id: area.id },
            headers: member_headers
        }.not_to change { target_account.areas.count }
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        delete "/api/account_areas/#{@account_area.id}",
          params: { account_id: target_account.id, area_id: area.id }
        expect(response).to have_http_status(:unauthorized)
      end

      it "エリアが削除されないこと" do
        expect {
          delete "/api/account_areas/#{@account_area.id}",
            params: { account_id: target_account.id, area_id: area.id }
        }.not_to change { target_account.areas.count }
      end
    end
  end
end
