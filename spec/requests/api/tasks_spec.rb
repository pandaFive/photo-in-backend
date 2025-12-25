# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::TasksController, type: :controller do
  describe "GET #index" do
    before do
      @admin = create(:account)
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id)
      @history = create(:assign_history, account_id: @member.id, assign_cycle_id: @cycle.id, ng: true)
      token = JsonWebToken.encode({ account_id: @admin.id })
      request.headers["Authorization"] = "Bearer #{token}"
    end
    context "typeがallの場合" do
      it "Status 200が返ってくること" do
        get :index, params: { type: "all" }
        expect(response).to have_http_status(200)
      end
      it "正しいデータが返ってくること" do
        get :index, params: { type: "all" }
        expect(JSON.parse(response.body)[0]["task_title"]).to eq(@task.task_title)
      end
    end
    context "typeがngの場合" do
      it "Status 200が返ってくること" do
        get :index, params: { type: "ng" }
        expect(response).to have_http_status(200)
      end
      it "正しいデータが返ってくること" do
        get :index, params: { type: "ng" }
        expect(JSON.parse(response.body)[0]["task_title"]).to eq(@task.task_title)
      end
    end
    context "typeが指定されなかった場合" do
      it "Status unprocessable_entityが返ってくること" do
        get :index
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it "エラーメッセージが返ってくること" do
        get :index
        expect(JSON.parse(response.body)["errors"]).to include("Type can't be blank")
      end
    end
    context "認証なしの場合" do
      before do
        request.headers["Authorization"] = nil
      end
      it "Status unauthorizedが返ってくること" do
        get :index, params: { type: "all" }
        expect(response).to have_http_status(:unauthorized)
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
      @admin = create(:account)
      @member = create(:account_member)
      @other_member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id, task_title: "元のタイトル")
    end

    # ヘルパー: タスクにメンバーを担当者として割り当てる
    def assign_to_member(task, account)
      cycle = create(:assign_cycle, task_id: task.id, is_active: true)
      create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id)
    end

    context "管理者が更新する場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 200が返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "更新されたタイトル" } }
        expect(response).to have_http_status(:ok)
      end

      it "更新されたデータが返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "更新されたタイトル" } }
        json_response = JSON.parse(response.body)
        expect(json_response["task_title"]).to eq("更新されたタイトル")
      end

      it "area_nameが返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "更新されたタイトル" } }
        json_response = JSON.parse(response.body)
        expect(json_response["area_name"]).to eq(@area.name)
      end
    end

    context "担当メンバーが更新する場合" do
      before do
        assign_to_member(@task, @member)
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 200が返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "担当者更新" } }
        expect(response).to have_http_status(:ok)
      end

      it "更新されたデータが返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "担当者更新" } }
        json_response = JSON.parse(response.body)
        expect(json_response["task_title"]).to eq("担当者更新")
      end
    end

    context "非担当メンバーが更新する場合" do
      before do
        assign_to_member(@task, @member)
        token = JsonWebToken.encode({ account_id: @other_member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status forbiddenが返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "不正な更新" } }
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "不正な更新" } }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end
    end

    context "割り当てなしタスクをメンバーが更新する場合" do
      before do
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status forbiddenが返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "不正な更新" } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "存在しないtaskのidが指定された場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 404が返ってくること" do
        put :update, params: { id: 9999, task: { task_title: "更新" } }
        expect(response).to have_http_status(:not_found)
      end

      it "エラーメッセージが返ってくること" do
        put :update, params: { id: 9999, task: { task_title: "更新" } }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("タスクが見つかりません")
      end
    end

    context "認証なしの場合" do
      it "Status unauthorizedが返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "更新" } }
        expect(response).to have_http_status(:unauthorized)
      end

      it "エラーメッセージが返ってくること" do
        put :update, params: { id: @task.id, task: { task_title: "更新" } }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("unauthorized")
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @admin = create(:account)
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
    end

    context "管理者が削除する場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 200が返ってくること" do
        delete :destroy, params: { id: @task.id }
        expect(response).to have_http_status(:ok)
      end

      it "正しいメッセージが返ってくること" do
        delete :destroy, params: { id: @task.id }
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("deleted")
      end

      it "タスクがDBから削除されること" do
        expect {
          delete :destroy, params: { id: @task.id }
        }.to change(Task, :count).by(-1)
      end
    end

    context "メンバーが削除しようとする場合" do
      before do
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status forbiddenが返ってくること" do
        delete :destroy, params: { id: @task.id }
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ってくること" do
        delete :destroy, params: { id: @task.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end

      it "タスクが削除されないこと" do
        expect {
          delete :destroy, params: { id: @task.id }
        }.not_to change(Task, :count)
      end
    end

    context "存在しないtaskのidが指定された場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 404が返ってくること" do
        delete :destroy, params: { id: 9999 }
        expect(response).to have_http_status(:not_found)
      end

      it "エラーメッセージが返ってくること" do
        delete :destroy, params: { id: 9999 }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("タスクが見つかりません")
      end
    end

    context "認証なしの場合" do
      it "Status unauthorizedが返ってくること" do
        delete :destroy, params: { id: @task.id }
        expect(response).to have_http_status(:unauthorized)
      end

      it "エラーメッセージが返ってくること" do
        delete :destroy, params: { id: @task.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("unauthorized")
      end
    end
  end

  describe "GET #show" do
    before do
      @admin = create(:account)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      token = JsonWebToken.encode({ account_id: @admin.id })
      request.headers["Authorization"] = "Bearer #{token}"
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

      it "area_nameが返ってくること" do
        get :show, params: { id: @task.id }
        json_response = JSON.parse(response.body)
        expect(json_response["area_name"]).to eq(@area.name)
      end
    end

    context "存在しないタスクの場合" do
      it "Status 404が返ってくること" do
        get :show, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end

      it "エラーメッセージが返ってくること" do
        get :show, params: { id: 999999 }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("タスクが見つかりません")
      end
    end

    context "認証なしの場合" do
      before do
        request.headers["Authorization"] = nil
      end

      it "Status unauthorizedが返ってくること" do
        get :show, params: { id: @task.id }
        expect(response).to have_http_status(:unauthorized)
      end

      it "エラーメッセージが返ってくること" do
        get :show, params: { id: @task.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("unauthorized")
      end
    end
  end

  describe "POST #add_tag" do
    before do
      @admin = create(:account, role: "admin")
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @tag = create(:tag, name: "重要")
      token = JsonWebToken.encode({ account_id: @admin.id })
      request.headers["Authorization"] = "Bearer #{token}"
    end

    context "認証済み管理者の場合" do
      context "有効なパラメータの場合" do
        it "Status 200が返ってくること" do
          post :add_tag, params: { id: @task.id, tag_id: @tag.id }
          expect(response).to have_http_status(:ok)
        end

        it "タスクにタグが紐付けられること" do
          expect {
            post :add_tag, params: { id: @task.id, tag_id: @tag.id }
          }.to change { @task.tags.count }.by(1)
        end

        it "紐付けられたタグ一覧が返ってくること" do
          post :add_tag, params: { id: @task.id, tag_id: @tag.id }
          json_response = JSON.parse(response.body)
          expect(json_response.length).to eq(1)
          expect(json_response[0]["name"]).to eq("重要")
        end
      end

      context "存在しないタスクの場合" do
        it "Status 404が返ってくること" do
          post :add_tag, params: { id: 999999, tag_id: @tag.id }
          expect(response).to have_http_status(:not_found)
        end
      end

      context "存在しないタグの場合" do
        it "Status 404が返ってくること" do
          post :add_tag, params: { id: @task.id, tag_id: 999999 }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "認証なしの場合" do
      before do
        request.headers["Authorization"] = nil
      end

      it "Status 401が返ってくること" do
        post :add_tag, params: { id: @task.id, tag_id: @tag.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "memberユーザーの場合" do
      before do
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 403が返ってくること" do
        post :add_tag, params: { id: @task.id, tag_id: @tag.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE #remove_tag" do
    before do
      @admin = create(:account, role: "admin")
      @member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @tag = create(:tag, name: "重要")
      @task.add_tag(@tag)
      token = JsonWebToken.encode({ account_id: @admin.id })
      request.headers["Authorization"] = "Bearer #{token}"
    end

    context "認証済み管理者の場合" do
      context "有効なパラメータの場合" do
        it "Status 200が返ってくること" do
          delete :remove_tag, params: { id: @task.id, tag_id: @tag.id }
          expect(response).to have_http_status(:ok)
        end

        it "タスクからタグが削除されること" do
          expect {
            delete :remove_tag, params: { id: @task.id, tag_id: @tag.id }
          }.to change { @task.tags.count }.by(-1)
        end

        it "残りのタグ一覧が返ってくること" do
          delete :remove_tag, params: { id: @task.id, tag_id: @tag.id }
          json_response = JSON.parse(response.body)
          expect(json_response.length).to eq(0)
        end
      end

      context "存在しないタスクの場合" do
        it "Status 404が返ってくること" do
          delete :remove_tag, params: { id: 999999, tag_id: @tag.id }
          expect(response).to have_http_status(:not_found)
        end
      end

      context "存在しないタグの場合" do
        it "Status 404が返ってくること" do
          delete :remove_tag, params: { id: @task.id, tag_id: 999999 }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "認証なしの場合" do
      before do
        request.headers["Authorization"] = nil
      end

      it "Status 401が返ってくること" do
        delete :remove_tag, params: { id: @task.id, tag_id: @tag.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "memberユーザーの場合" do
      before do
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 403が返ってくること" do
        delete :remove_tag, params: { id: @task.id, tag_id: @tag.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PUT #completed" do
    before do
      @admin = create(:account)
      @member = create(:account_member)
      @other_member = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id, is_active: true)
      @history = create(:assign_history, account_id: @member.id, assign_cycle_id: @cycle.id, completed: false, ng: false)
    end

    context "認証なしの場合" do
      it "Status 401が返ってくること" do
        put :completed, params: { id: @history.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "管理者が完了する場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 200が返ってくること" do
        put :completed, params: { id: @history.id }
        expect(response).to have_http_status(:ok)
      end

      it "completedがtrueになること" do
        put :completed, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["result"]).to be true
      end

      it "正しいメッセージが返ってくること" do
        put :completed, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("change completed")
      end

      it "AssignHistoryのcompletedがtrueに更新されること" do
        put :completed, params: { id: @history.id }
        expect(@history.reload.completed).to be true
      end

      it "AssignCycleのis_activeがfalseに更新されること" do
        put :completed, params: { id: @history.id }
        expect(@cycle.reload.is_active).to be false
      end
    end

    context "担当メンバーが自分のタスクを完了する場合" do
      before do
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 200が返ってくること" do
        put :completed, params: { id: @history.id }
        expect(response).to have_http_status(:ok)
      end

      it "AssignHistoryのcompletedがtrueに更新されること" do
        put :completed, params: { id: @history.id }
        expect(@history.reload.completed).to be true
      end
    end

    context "非担当メンバーが完了しようとする場合" do
      before do
        token = JsonWebToken.encode({ account_id: @other_member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status forbiddenが返ってくること" do
        put :completed, params: { id: @history.id }
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ってくること" do
        put :completed, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end

      it "AssignHistoryが更新されないこと" do
        put :completed, params: { id: @history.id }
        expect(@history.reload.completed).to be false
      end
    end

    context "存在しないAssignHistoryの場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 404が返ってくること" do
        put :completed, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end

      it "エラーメッセージが返ってくること" do
        put :completed, params: { id: 999999 }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("担当履歴が見つかりません")
      end
    end

    context "既に完了済みの場合" do
      before do
        @history.update(completed: true)
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status unprocessable_entityが返ってくること" do
        put :completed, params: { id: @history.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが返ってくること" do
        put :completed, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("既に完了しています")
      end
    end
  end

  describe "PUT #ng" do
    before do
      @admin = create(:account)
      @member = create(:account_member)
      @other_member = create(:account_member)
      @area = create(:area)
      @member.add_area(@area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id, is_active: true)
      @history = create(:assign_history, account_id: @member.id, assign_cycle_id: @cycle.id, ng: false, completed: false)
    end

    context "認証なしの場合" do
      it "Status 401が返ってくること" do
        put :ng, params: { id: @history.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "管理者がNG操作する場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 200が返ってくること" do
        put :ng, params: { id: @history.id }
        expect(response).to have_http_status(:ok)
      end

      it "resultがtrueを返すこと" do
        put :ng, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["result"]).to be true
      end

      it "AssignHistoryのngがtrueに更新されること" do
        put :ng, params: { id: @history.id }
        expect(@history.reload.ng).to be true
      end
    end

    context "担当メンバーが自分のタスクをNG操作する場合" do
      before do
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 200が返ってくること" do
        put :ng, params: { id: @history.id }
        expect(response).to have_http_status(:ok)
      end

      it "AssignHistoryのngがtrueに更新されること" do
        put :ng, params: { id: @history.id }
        expect(@history.reload.ng).to be true
      end
    end

    context "非担当メンバーがNG操作しようとする場合" do
      before do
        token = JsonWebToken.encode({ account_id: @other_member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status forbiddenが返ってくること" do
        put :ng, params: { id: @history.id }
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ってくること" do
        put :ng, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end

      it "AssignHistoryが更新されないこと" do
        put :ng, params: { id: @history.id }
        expect(@history.reload.ng).to be false
      end
    end

    context "存在しないAssignHistoryの場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 404が返ってくること" do
        put :ng, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end

      it "エラーメッセージが返ってくること" do
        put :ng, params: { id: 999999 }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("担当履歴が見つかりません")
      end
    end

    context "無効なIDフォーマットの場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "非数値IDでStatus 422が返ること" do
        put :ng, params: { id: "invalid" }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "0のIDでStatus 422が返ること" do
        put :ng, params: { id: "0" }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "負数のIDでStatus 422が返ること" do
        put :ng, params: { id: "-1" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "既にNGの場合" do
      before do
        @history.update(ng: true)
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status unprocessable_entityが返ってくること" do
        put :ng, params: { id: @history.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが返ってくること" do
        put :ng, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("既にNGです")
      end
    end

    context "既に完了済みの場合" do
      before do
        @history.update(completed: true)
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status unprocessable_entityが返ってくること" do
        put :ng, params: { id: @history.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが返ってくること" do
        put :ng, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("既に完了しています")
      end
    end

    context "NG後に再割り当てが実行される場合" do
      before do
        @another_member = create(:account_member)
        @another_member.add_area(@area)
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "新しいAssignHistoryが作成されること" do
        expect {
          put :ng, params: { id: @history.id }
        }.to change(AssignHistory, :count).by(1)
      end

      it "新しい担当者に割り当てられること" do
        put :ng, params: { id: @history.id }
        new_history = @cycle.assign_histories.where.not(id: @history.id).last
        expect(new_history.account_id).to eq(@another_member.id)
      end

      it "messageがcompleteを返すこと" do
        put :ng, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("complete")
      end
    end

    context "再割り当て対象者がいない場合" do
      before do
        # memberが唯一のエリア担当者で、NG済みになるため再割り当て不可
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 200が返ること（NG自体は成功）" do
        put :ng, params: { id: @history.id }
        expect(response).to have_http_status(:ok)
      end

      it "messageがfailedを返すこと" do
        put :ng, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("failed")
      end

      it "resultがtrueを返すこと（NG操作自体は成功）" do
        put :ng, params: { id: @history.id }
        json_response = JSON.parse(response.body)
        expect(json_response["result"]).to be true
      end
    end
  end

  describe "POST #create_new_cycle" do
    before do
      @admin = create(:account)
      @member = create(:account_member)
      @area = create(:area)
      @member.add_area(@area)
      @task = create(:task, area_id: @area.id)
    end

    context "認証なしの場合" do
      it "Status 401が返ること" do
        post :create_new_cycle, params: { id: @task.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "一般メンバーの場合" do
      before do
        token = JsonWebToken.encode({ account_id: @member.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 403が返ること" do
        post :create_new_cycle, params: { id: @task.id }
        expect(response).to have_http_status(:forbidden)
      end

      it "エラーメッセージが返ること" do
        post :create_new_cycle, params: { id: @task.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("権限がありません")
      end
    end

    context "管理者で有効なパラメータの場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 200が返ってくること" do
        post :create_new_cycle, params: { id: @task.id }
        expect(response).to have_http_status(:ok)
      end

      it "新しいAssignCycleが作成されること" do
        expect {
          post :create_new_cycle, params: { id: @task.id }
        }.to change(AssignCycle, :count).by(1)
      end

      it "Presenter形式でタスクが返ること" do
        post :create_new_cycle, params: { id: @task.id }
        json_response = JSON.parse(response.body)
        expect(json_response["task_title"]).to eq(@task.task_title)
      end
    end

    context "管理者で存在しないタスクの場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 404が返ってくること" do
        post :create_new_cycle, params: { id: 999999 }
        expect(response).to have_http_status(:not_found)
      end

      it "エラーメッセージが返ること" do
        post :create_new_cycle, params: { id: 999999 }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("タスクが見つかりません")
      end
    end

    context "管理者で割り当て可能なメンバーがいない場合" do
      before do
        # メンバーをエリアから外す
        @member.areas.delete(@area)
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "Status 422が返ること" do
        post :create_new_cycle, params: { id: @task.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが返ること" do
        post :create_new_cycle, params: { id: @task.id }
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("割り当て可能なメンバーがいません")
      end

      it "サイクルは作成されないこと（トランザクションがロールバックされるため）" do
        expect {
          post :create_new_cycle, params: { id: @task.id }
        }.not_to change(AssignCycle, :count)
      end
    end

    context "無効なIDフォーマットの場合" do
      before do
        token = JsonWebToken.encode({ account_id: @admin.id })
        request.headers["Authorization"] = "Bearer #{token}"
      end

      it "文字列のIDでStatus 422が返ること" do
        post :create_new_cycle, params: { id: "abc" }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "0のIDでStatus 422が返ること" do
        post :create_new_cycle, params: { id: "0" }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "負のIDでStatus 422が返ること" do
        post :create_new_cycle, params: { id: "-1" }
        expect(response).to have_http_status(:unprocessable_entity)
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
