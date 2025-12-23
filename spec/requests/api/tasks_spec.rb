require "rails_helper"

RSpec.describe Api::TasksController, type: :controller do
  describe "GET #index" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id)
      @history = create(:assign_history, account_id: @member.id, assign_cycle_id: @cycle.id, ng: true)
    end
    context "typeがallの場合" do
      it "Status 200が返ってくること" do
        get :index, params: { type: "all" }
        expect(response).to have_http_status(200)
      end
      it "正しいデータが返ってくること" do
        get :index, params: { type: "all" }
        expect(JSON.parse(response.body)[0]["title"]).to eq(@task.task_title)
      end
    end
    context "typeがngの場合" do
      it "Status 200が返ってくること" do
        get :index, params: { type: "ng" }
        expect(response).to have_http_status(200)
      end
      it "正しいデータが返ってくること" do
        get :index, params: { type: "ng" }
        expect(JSON.parse(response.body)[0]["title"]).to eq(@task.task_title)
      end
    end
    context "typeが指定されなかった場合" do
      it "Status 200が返ってくること" do
        get :index
        expect(response).to have_http_status(200)
      end
      it "正しいデータが返ってくること" do
        get :index
        expect(JSON.parse(response.body)["message"]).to eq("not type")
      end
    end
  end
  describe "POST #create" do
    before do
      @before_count = Task.all.count
      @admin = create(:account)
      @member = create(:account_member)
      @area = create(:area, id: 1)
      token = JsonWebToken.encode({ account_id: @admin.id })
      request.headers["Authorization"] = "Bearer #{token}"
    end
    context "タスクの登録が成功した場合" do
      before do
        @member.add_areas([@area.id])
      end
      it "Status createdが返ってくること" do
        post :create, params: { task: { task_title: "x テスト登録" } }
        expect(response).to have_http_status(:created)
      end
      it "正しいデータが返ってくること" do
        post :create, params: { task: { task_title: "x テスト登録" } }
        expect(JSON.parse(response.body)["task_title"]).to eq("x テスト登録")
      end
    end
    context "タスクタイトルが指定されなかった場合" do
      it "Status unprocessable_entityが返ってくること" do
        post :create, params: { task: { task_title: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    context "認証なしの場合" do
      before do
        request.headers["Authorization"] = nil
      end
      it "Status unauthorizedが返ってくること" do
        post :create, params: { task: { task_title: "テスト" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
    context "member権限の場合" do
      before do
        member_token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{member_token}"
      end
      it "Status forbiddenが返ってくること" do
        post :create, params: { task: { task_title: "テスト" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  describe "PUT #update" do
    before do
      @area = create(:area)
      @task = create(:task, area_id: @area.id, task_title: "元のタイトル")
    end
    context "更新が成功した場合" do
      it "Status 200が返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "更新されたタイトル" } }
        expect(response).to have_http_status(200)
      end

      it "更新されたデータが返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "更新されたタイトル" } }
        expect(JSON.parse(response.body)["task_title"]).to eq("更新されたタイトル")
      end
    end

    context "存在しないtaskのidが指定された場合" do
      it "Status 404が返ってくること" do
        put :update, params: { id: 9999, task: { task_title: "更新" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
    end

    context "削除が成功した場合" do
      it "Status 204が返ってくること" do
        delete :destroy, params: { id: @task.id }
        expect(response).to have_http_status(204)
      end
    end

    context "存在しないtaskのidが指定された場合" do
      it "Status 404が返ってくること" do
        delete :destroy, params: { id: 9999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #show" do
    before do
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
    end

    context "存在するタスクの場合" do
      it "Status 200が返ってくること" do
        get :show, params: { id: @task.id }
        expect(response).to have_http_status(:ok)
      end

      it "正しいデータが返ってくること" do
        get :show, params: { id: @task.id }
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(@task.id)
        expect(json_response["task_title"]).to eq(@task.task_title)
      end
    end

    context "存在しないタスクの場合" do
      it "Status 404が返ってくること" do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #add_tag" do
    before do
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @tag = create(:tag, name: "重要")
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post :add_tag, params: { id: @task.id, task_id: @task.id, tag_id: @tag.id }
        expect(response).to have_http_status(:ok)
      end

      it "タスクにタグが紐付けられること" do
        expect {
          post :add_tag, params: { id: @task.id, task_id: @task.id, tag_id: @tag.id }
        }.to change { @task.tags.count }.by(1)
      end

      it "紐付けられたタグ一覧が返ってくること" do
        post :add_tag, params: { id: @task.id, task_id: @task.id, tag_id: @tag.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(1)
        expect(json_response[0]["name"]).to eq("重要")
      end
    end

    context "存在しないタスクの場合" do
      it "Status 404が返ってくること" do
        post :add_tag, params: { id: 999999, task_id: 999999, tag_id: @tag.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "存在しないタグの場合" do
      it "Status 404が返ってくること" do
        post :add_tag, params: { id: @task.id, task_id: @task.id, tag_id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #remove_tag" do
    before do
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @tag = create(:tag, name: "重要")
      @task.add_tag(@tag)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        delete :remove_tag, params: { id: @task.id, task_id: @task.id, tag_id: @tag.id }
        expect(response).to have_http_status(:ok)
      end

      it "タスクからタグが削除されること" do
        expect {
          delete :remove_tag, params: { id: @task.id, task_id: @task.id, tag_id: @tag.id }
        }.to change { @task.tags.count }.by(-1)
      end

      it "残りのタグ一覧が返ってくること" do
        delete :remove_tag, params: { id: @task.id, task_id: @task.id, tag_id: @tag.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(0)
      end
    end

    context "存在しないタスクの場合" do
      it "Status 404が返ってくること" do
        delete :remove_tag, params: { id: 999999, task_id: 999999, tag_id: @tag.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PUT #completed" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id)
      @history = create(:assign_history, account_id: @member.id, assign_cycle_id: @cycle.id, completed: false)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        put :completed, params: { id: @history.id }
        expect(response).to have_http_status(:ok)
      end

      it "completedがtrueになること" do
        put :completed, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["result"]).to be true
      end
    end

    context "存在しないAssignHistoryの場合" do
      it "Status 404が返ってくること" do
        put :completed, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PUT #ng" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @member.add_area(@area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id)
      @history = create(:assign_history, account_id: @member.id, assign_cycle_id: @cycle.id, ng: false)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        put :ng, params: { id: @history.id }
        expect(response).to have_http_status(:ok)
      end

      it "ngがtrueになること" do
        put :ng, params: { id: @history.id }
        @history.reload
        expect(@history.ng).to be true
      end
    end

    context "存在しないAssignHistoryの場合" do
      it "Status 404が返ってくること" do
        put :ng, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #create_new_cycle" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @member.add_area(@area)
      @task = create(:task, area_id: @area.id)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post :create_new_cycle, params: { id: @task.id }
        expect(response).to have_http_status(:ok)
      end

      it "新しいAssignCycleが作成されること" do
        expect {
          post :create_new_cycle, params: { id: @task.id }
        }.to change(AssignCycle, :count).by(1)
      end
    end

    context "存在しないタスクの場合" do
      it "Status 404が返ってくること" do
        post :create_new_cycle, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #unfulfilleds_count" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id)
    end

    it "Status 200が返ってくること" do
      get :unfulfilleds_count
      expect(response).to have_http_status(:ok)
    end

    it "数値が返ってくること" do
      get :unfulfilleds_count
      json_response = JSON.parse(response.body)
      expect(json_response).to be_a(Integer)
    end
  end

  describe "GET #get_complete_data" do
    it "Status 200が返ってくること" do
      get :get_complete_data
      expect(response).to have_http_status(:ok)
    end

    it "ハッシュが返ってくること" do
      get :get_complete_data
      json_response = JSON.parse(response.body)
      expect(json_response).to be_a(Hash)
    end
  end

  describe "GET #get_account_task" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id)
      @history = create(:assign_history, account_id: @member.id, assign_cycle_id: @cycle.id, completed: false, ng: false)
    end

    it "Status 200が返ってくること" do
      get :get_account_task, params: { id: @member.id }
      expect(response).to have_http_status(:ok)
    end

    it "アカウントに割り当てられたタスクが返ってくること" do
      get :get_account_task, params: { id: @member.id }
      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
    end
  end
end
