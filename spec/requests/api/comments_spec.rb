require "rails_helper"

RSpec.describe "Api::Comments", type: :request do
  describe "GET /api/comments" do
    before do
      @admin = create(:account)
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @admin_comment = create(:comment, account: @admin, task: @task, content: "管理者コメント")
      @member_comment = create(:comment, account: @member, task: @task, content: "メンバーコメント")
    end

    context "adminユーザーがアクセスする場合" do
      it "Status 200が返ってくること" do
        get "/api/comments", params: { taskId: @task.id, accountId: @admin.id }
        expect(response).to have_http_status(:ok)
      end

      it "全てのコメントが返ってくること" do
        get "/api/comments", params: { taskId: @task.id, accountId: @admin.id }
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(2)
      end

      it "正しい形式のデータが返ってくること" do
        get "/api/comments", params: { taskId: @task.id, accountId: @admin.id }
        json_response = JSON.parse(response.body)
        expect(json_response[0]).to have_key("id")
        expect(json_response[0]).to have_key("content")
        expect(json_response[0]).to have_key("name")
      end
    end

    context "memberユーザーがアクセスする場合" do
      it "Status 200が返ってくること" do
        get "/api/comments", params: { taskId: @task.id, accountId: @member.id }
        expect(response).to have_http_status(:ok)
      end

      it "自分とadminのコメントのみが返ってくること" do
        other_member = create(:account_member, name: "other_member")
        create(:comment, account: other_member, task: @task, content: "他メンバーコメント")

        get "/api/comments", params: { taskId: @task.id, accountId: @member.id }
        json_response = JSON.parse(response.body)
        # 自分のコメント + adminのコメントのみ（他メンバーは含まない）
        expect(json_response.length).to eq(2)
      end
    end
  end

  describe "GET /api/comments/:id" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @comment = create(:comment, account: @member, task: @task, content: "テストコメント")
    end

    context "存在するコメントの場合" do
      it "Status 200が返ってくること" do
        get "/api/comments/#{@comment.id}"
        expect(response).to have_http_status(:ok)
      end

      it "正しいデータが返ってくること" do
        get "/api/comments/#{@comment.id}"
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(@comment.id)
        expect(json_response["content"]).to eq("テストコメント")
      end
    end

    context "存在しないコメントの場合" do
      it "Status 404が返ってくること" do
        get "/api/comments/999999"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/comments" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        post "/api/comments", params: { comment: { content: "新規コメント", task_id: @task.id, account_id: @member.id } }
        expect(response).to have_http_status(:ok)
      end

      it "コメントが作成されること" do
        expect {
          post "/api/comments", params: { comment: { content: "新規コメント", task_id: @task.id, account_id: @member.id } }
        }.to change(Comment, :count).by(1)
      end

      it "作成されたデータが返ってくること" do
        post "/api/comments", params: { comment: { content: "新規コメント", task_id: @task.id, account_id: @member.id } }
        json_response = JSON.parse(response.body)
        expect(json_response["content"]).to eq("新規コメント")
      end
    end

    context "無効なパラメータの場合" do
      # Note: Comment modelにcontentのバリデーションがないため、空でも保存される
      # 将来的にバリデーション追加時はこのテストを更新する
      it "contentが空の場合でも保存されること（バリデーションなし）" do
        post "/api/comments", params: { comment: { content: "", task_id: @task.id, account_id: @member.id } }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PUT /api/comments/:id" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @comment = create(:comment, account: @member, task: @task, content: "元のコメント")
    end

    context "有効なパラメータの場合" do
      it "Status 200が返ってくること" do
        put "/api/comments/#{@comment.id}", params: { comment: { content: "更新後のコメント" } }
        expect(response).to have_http_status(:ok)
      end

      it "更新されたデータが返ってくること" do
        put "/api/comments/#{@comment.id}", params: { comment: { content: "更新後のコメント" } }
        json_response = JSON.parse(response.body)
        expect(json_response["content"]).to eq("更新後のコメント")
      end

      it "DBが更新されていること" do
        put "/api/comments/#{@comment.id}", params: { comment: { content: "更新後のコメント" } }
        @comment.reload
        expect(@comment.content).to eq("更新後のコメント")
      end
    end

    context "存在しないコメントの場合" do
      it "Status 404が返ってくること" do
        put "/api/comments/999999", params: { comment: { content: "更新" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/comments/:id" do
    before do
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @comment = create(:comment, account: @member, task: @task)
    end

    context "存在するコメントの場合" do
      it "Status 200が返ってくること" do
        delete "/api/comments/#{@comment.id}"
        expect(response).to have_http_status(:ok)
      end

      it "成功メッセージが返ってくること" do
        delete "/api/comments/#{@comment.id}"
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("complete")
      end

      it "コメントが削除されること" do
        expect {
          delete "/api/comments/#{@comment.id}"
        }.to change(Comment, :count).by(-1)
      end
    end

    context "存在しないコメントの場合" do
      it "Status 404が返ってくること" do
        delete "/api/comments/999999"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
