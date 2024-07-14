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
      @member = create(:account_member)
      @area = create(:area, id: 1)
    end
    context "タスクの登録が成功した場合" do
      before do
        @member.add_areas([@area.id])
      end
      it "Status 200が返ってくること" do
        post :create, params: { task: { task_title: "x テスト登録" } }
        expect(response).to have_http_status(200)
      end
      it "正しいデータが返ってくること" do
        post :create, params: { task: { task_title: "x テスト登録" } }
        expect(JSON.parse(response.body)["task_title"]).to eq("x テスト登録")
      end
    end
    context "タスクタイトルが指定されなかった場合" do
      it "Status 500が返ってくること" do
        post :create
        expect(response).to have_http_status(500)
      end
    end
  end
  describe "PUT #update" do
    before do
      @task = create(:task)
    end
    context "更新が成功した場合" do
    end
  end
end
