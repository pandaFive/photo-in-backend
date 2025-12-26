# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Assigns", type: :request do
  let!(:admin) { create(:account, role: "admin") }
  let!(:member) { create(:account_member) }
  let(:admin_token) { JsonWebToken.encode({ account_id: admin.id }) }
  let(:member_token) { JsonWebToken.encode({ account_id: member.id }) }
  let(:admin_headers) { { "Authorization" => "Bearer #{admin_token}" } }
  let(:member_headers) { { "Authorization" => "Bearer #{member_token}" } }

  describe "POST /api/tasks/assign/cycle" do
    before do
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      # memberにエリアを割り当て、割り当て可能な状態にする
      member.areas << @area
    end

    context "認証済みadminユーザーの場合" do
      context "有効なパラメータの場合" do
        it "Status 201が返ってくること" do
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: @task.id } },
            headers: admin_headers
          expect(response).to have_http_status(:created)
        end

        it "AssignCycleが作成されること" do
          expect {
            post "/api/tasks/assign/cycle",
              params: { assign_cycle: { task_id: @task.id } },
              headers: admin_headers
          }.to change(AssignCycle, :count).by(1)
        end

        it "作成されたデータが返ってくること" do
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: @task.id } },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["task_id"]).to eq(@task.id)
          expect(json_response["is_active"]).to be true
        end

        it "AssignHistoryが作成されること" do
          expect {
            post "/api/tasks/assign/cycle",
              params: { assign_cycle: { task_id: @task.id } },
              headers: admin_headers
          }.to change(AssignHistory, :count).by(1)
        end
      end

      context "既存のサイクルがある場合" do
        before do
          @existing_cycle = create(:assign_cycle, task: @task, is_active: true)
        end

        it "既存のサイクルが非アクティブになること" do
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: @task.id } },
            headers: admin_headers
          @existing_cycle.reload
          expect(@existing_cycle.is_active).to be false
        end
      end

      context "task_idが指定されていない場合" do
        it "Status 422が返ってくること" do
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: nil } },
            headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: nil } },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"].first).to include("タスクID")
        end
      end

      context "存在しないtask_idが指定された場合" do
        it "Status 404が返ってくること" do
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: 999999 } },
            headers: admin_headers
          expect(response).to have_http_status(:not_found)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: 999999 } },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("タスクが見つかりません")
        end
      end

      context "割り当て可能なメンバーがいない場合" do
        before do
          # memberからエリアを削除
          member.areas.clear
        end

        it "Status 422が返ってくること" do
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: @task.id } },
            headers: admin_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "エラーメッセージが返ってくること" do
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: @task.id } },
            headers: admin_headers
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("割り当て可能なメンバーがいません")
        end

        it "AssignCycleが作成されないこと" do
          expect {
            post "/api/tasks/assign/cycle",
              params: { assign_cycle: { task_id: @task.id } },
              headers: admin_headers
          }.not_to change(AssignCycle, :count)
        end
      end
    end

    context "認証済みmemberユーザーの場合" do
      it "Status 403が返ってくること" do
        post "/api/tasks/assign/cycle",
          params: { assign_cycle: { task_id: @task.id } },
          headers: member_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ってくること" do
        post "/api/tasks/assign/cycle",
          params: { assign_cycle: { task_id: @task.id } },
          headers: member_headers
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end

      it "AssignCycleが作成されないこと" do
        expect {
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: @task.id } },
            headers: member_headers
        }.not_to change(AssignCycle, :count)
      end
    end

    context "未認証の場合" do
      it "Status 401が返ってくること" do
        post "/api/tasks/assign/cycle",
          params: { assign_cycle: { task_id: @task.id } }
        expect(response).to have_http_status(:unauthorized)
      end

      it "AssignCycleが作成されないこと" do
        expect {
          post "/api/tasks/assign/cycle",
            params: { assign_cycle: { task_id: @task.id } }
        }.not_to change(AssignCycle, :count)
      end
    end
  end
end
