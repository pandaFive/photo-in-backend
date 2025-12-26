# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::TagAccounts", type: :request do
  let!(:admin) { create(:account, role: "admin") }
  let!(:member) { create(:account_member) }
  let(:admin_token) { JsonWebToken.encode({ account_id: admin.id }) }
  let(:member_token) { JsonWebToken.encode({ account_id: member.id }) }
  let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:member_headers) { { "Authorization" => "Bearer #{member_token}" } }

  describe "POST /api/tag_accounts" do
    let!(:target_account) { create(:account_member) }
    let!(:tag) { create(:tag, name: "重要") }

    context "認証済みadminユーザーの場合" do
      context "有効なパラメータの場合" do
        it "Status 200が返ってくること" do
          post "/api/tag_accounts",
            params: { account_id: target_account.id, tag_id: tag.id },
            headers: admin_headers
          expect(response).to have_http_status(:ok)
        end

        it "アカウントにタグが紐付けられること" do
          expect {
            post "/api/tag_accounts",
              params: { account_id: target_account.id, tag_id: tag.id },
              headers: admin_headers
          }.to change { target_account.tags.count }.by(1)
        end

        it "紐付けられたタグ一覧が返ってくること" do
          post "/api/tag_accounts",
            params: { account_id: target_account.id, tag_id: tag.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response.length).to eq(1)
          expect(json_response[0]["name"]).to eq("重要")
        end
      end

      context "既にタグが追加されている場合" do
        before do
          target_account.tags << tag
        end

        it "Status 409が返ってくること" do
          post "/api/tag_accounts",
            params: { account_id: target_account.id, tag_id: tag.id },
            headers: admin_headers
          expect(response).to have_http_status(:conflict)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/tag_accounts",
            params: { account_id: target_account.id, tag_id: tag.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("このタグは既に追加されています")
        end
      end

      context "存在しないアカウントの場合" do
        it "Status 404が返ってくること" do
          post "/api/tag_accounts",
            params: { account_id: 999999, tag_id: tag.id },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/tag_accounts",
            params: { account_id: 999999, tag_id: tag.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("アカウントが見つかりません")
        end
      end

      context "存在しないタグの場合" do
        it "Status 404が返ってくること" do
          post "/api/tag_accounts",
            params: { account_id: target_account.id, tag_id: 999999 },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/tag_accounts",
            params: { account_id: target_account.id, tag_id: 999999 },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("タグが見つかりません")
        end
      end

      context "account_idがない場合" do
        it "Status 422が返ってくること" do
          post "/api/tag_accounts",
            params: { tag_id: tag.id },
            headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "tag_idがない場合" do
        it "Status 422が返ってくること" do
          post "/api/tag_accounts",
            params: { account_id: target_account.id },
            headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "認証済みmemberユーザーの場合" do
      it "Status 403が返ってくること" do
        post "/api/tag_accounts",
          params: { account_id: target_account.id, tag_id: tag.id },
          headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ってくること" do
        post "/api/tag_accounts",
          params: { account_id: target_account.id, tag_id: tag.id },
          headers: member_headers
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end

      it "タグが追加されないこと" do
        expect {
          post "/api/tag_accounts",
            params: { account_id: target_account.id, tag_id: tag.id },
            headers: member_headers
        }.not_to change { target_account.tags.count }
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        post "/api/tag_accounts",
          params: { account_id: target_account.id, tag_id: tag.id }
        expect(response).to have_http_status(:unauthorized)
      end

      it "タグが追加されないこと" do
        expect {
          post "/api/tag_accounts",
            params: { account_id: target_account.id, tag_id: tag.id }
        }.not_to change { target_account.tags.count }
      end
    end
  end

  describe "DELETE /api/tag_accounts/:id" do
    let!(:target_account) { create(:account_member) }
    let!(:tag) { create(:tag, name: "重要") }

    before do
      target_account.add_tag(tag)
      @tag_account = TagAccount.find_by(account_id: target_account.id, tag_id: tag.id)
    end

    context "認証済みadminユーザーの場合" do
      context "有効なパラメータの場合" do
        it "Status 200が返ってくること" do
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: target_account.id, tag_id: tag.id },
            headers: admin_headers
          expect(response).to have_http_status(:ok)
        end

        it "アカウントからタグが削除されること" do
          expect {
            delete "/api/tag_accounts/#{@tag_account.id}",
              params: { account_id: target_account.id, tag_id: tag.id },
              headers: admin_headers
          }.to change { target_account.tags.count }.by(-1)
        end

        it "残りのタグ一覧が返ってくること" do
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: target_account.id, tag_id: tag.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response.length).to eq(0)
        end
      end

      context "存在しないアカウントの場合" do
        it "Status 404が返ってくること" do
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: 999999, tag_id: tag.id },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: 999999, tag_id: tag.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("アカウントが見つかりません")
        end
      end

      context "存在しないタグの場合" do
        it "Status 404が返ってくること" do
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: target_account.id, tag_id: 999999 },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: target_account.id, tag_id: 999999 },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("タグが見つかりません")
        end
      end

      context "紐付いていないタグの場合" do
        let!(:other_tag) { create(:tag, name: "緊急") }

        it "Status 404が返ってくること" do
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: target_account.id, tag_id: other_tag.id },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: target_account.id, tag_id: other_tag.id },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("このタグはアカウントに紐付いていません")
        end
      end
    end

    context "認証済みmemberユーザーの場合" do
      it "Status 403が返ってくること" do
        delete "/api/tag_accounts/#{@tag_account.id}",
          params: { account_id: target_account.id, tag_id: tag.id },
          headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ってくること" do
        delete "/api/tag_accounts/#{@tag_account.id}",
          params: { account_id: target_account.id, tag_id: tag.id },
          headers: member_headers
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end

      it "タグが削除されないこと" do
        expect {
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: target_account.id, tag_id: tag.id },
            headers: member_headers
        }.not_to change { target_account.tags.count }
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        delete "/api/tag_accounts/#{@tag_account.id}",
          params: { account_id: target_account.id, tag_id: tag.id }
        expect(response).to have_http_status(:unauthorized)
      end

      it "タグが削除されないこと" do
        expect {
          delete "/api/tag_accounts/#{@tag_account.id}",
            params: { account_id: target_account.id, tag_id: tag.id }
        }.not_to change { target_account.tags.count }
      end
    end
  end
end
