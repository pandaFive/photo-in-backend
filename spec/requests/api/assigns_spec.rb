require "rails_helper"

RSpec.describe Api::AssignsController, type: :controller do
  describe "POST #cycle_create" do
    before do
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post :cycle_create, params: { assign_cycle: { task_id: @task.id } }
        expect(response).to have_http_status(:ok)
      end

      it "AssignCycleが作成されること" do
        expect {
          post :cycle_create, params: { assign_cycle: { task_id: @task.id } }
        }.to change(AssignCycle, :count).by(1)
      end

      it "作成されたデータが返ってくること" do
        post :cycle_create, params: { assign_cycle: { task_id: @task.id } }
        json_response = JSON.parse(response.body)
        expect(json_response["task_id"]).to eq(@task.id)
      end
    end

    context "task_idが指定されていない場合" do
      it "Status 422が返ってくること" do
        post :cycle_create, params: { assign_cycle: { task_id: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが返ってくること" do
        post :cycle_create, params: { assign_cycle: { task_id: nil } }
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("message")
        expect(json_response["status"]).to eq(422)
      end
    end

    context "存在しないtask_idが指定された場合" do
      it "Status 422が返ってくること" do
        post :cycle_create, params: { assign_cycle: { task_id: 999999 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
