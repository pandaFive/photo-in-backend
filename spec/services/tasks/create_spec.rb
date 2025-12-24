# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::Create, type: :service do
  let(:admin_account) { create(:account) }
  let(:member_account) { create(:account_member) }
  let!(:area) { create(:area, name: "テストエリア") }

  describe "#call" do
    describe "正常系" do
      # アサイン可能なアカウントを作成
      let!(:member_with_area) { create(:account_member, areas: [area]) }

      context "task_titleとarea_idを指定した場合" do
        let(:params) { { task_title: "テスト撮影タスク", area_id: area.id } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
        end

        it "taskオブジェクトを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.task).to be_a(Task)
          expect(result.task.task_title).to eq("テスト撮影タスク")
          expect(result.task.area_id).to eq(area.id)
        end

        it "statusが:createdであること" do
          result = described_class.new.call(params, admin_account)
          expect(result.status).to eq(:created)
        end

        it "errorsが空であること" do
          result = described_class.new.call(params, admin_account)
          expect(result.errors).to be_empty
        end

        it "タスクがDBに保存されること" do
          expect {
            described_class.new.call(params, admin_account)
          }.to change(Task, :count).by(1)
        end

        it "AssignCycleが作成されること" do
          expect {
            described_class.new.call(params, admin_account)
          }.to change(AssignCycle, :count).by(1)
        end
      end

      context "task_titleのみ指定（タイトルからエリア推論）" do
        let(:params) { { task_title: "テストエリアの撮影タスク" } }

        it "タイトルからエリアを推論してタスクを作成すること" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
          expect(result.task.area_id).to eq(area.id)
        end
      end

      context "エリアが推論できない場合（デフォルトエリア使用）" do
        let(:params) { { task_title: "不明なタスク" } }

        it "デフォルトエリアを使用すること" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
          expect(result.task.area_id).to eq(Area.first.id)
        end
      end
    end

    describe "異常系" do
      context "認可エラー" do
        context "memberアカウントの場合" do
          let(:params) { { task_title: "テスト撮影タスク", area_id: area.id } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, member_account)
            expect(result.success?).to be false
          end

          it "statusが:forbiddenであること" do
            result = described_class.new.call(params, member_account)
            expect(result.status).to eq(:forbidden)
          end

          it "権限エラーメッセージを返すこと" do
            result = described_class.new.call(params, member_account)
            expect(result.errors).to include("権限がありません")
          end
        end

        context "current_accountがnilの場合" do
          let(:params) { { task_title: "テスト撮影タスク", area_id: area.id } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, nil)
            expect(result.success?).to be false
          end

          it "statusが:forbiddenであること" do
            result = described_class.new.call(params, nil)
            expect(result.status).to eq(:forbidden)
          end
        end
      end

      context "バリデーションエラー" do
        context "task_titleが空の場合" do
          let(:params) { { task_title: "", area_id: area.id } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, admin_account)
            expect(result.success?).to be false
          end

          it "statusが:unprocessable_entityであること" do
            result = described_class.new.call(params, admin_account)
            expect(result.status).to eq(:unprocessable_entity)
          end

          it "バリデーションエラーメッセージを返すこと" do
            result = described_class.new.call(params, admin_account)
            expect(result.errors).to include("Task title can't be blank")
          end
        end
      end

      context "エリアが存在しない場合" do
        before do
          Area.destroy_all
        end

        let(:params) { { task_title: "テスト撮影タスク" } }

        it "success?がfalseを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be false
        end

        it "statusが:bad_requestであること" do
          result = described_class.new.call(params, admin_account)
          expect(result.status).to eq(:bad_request)
        end

        it "エラーメッセージを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.errors).to include("エリアが正しく設定されていません")
        end
      end
    end

    describe "アサイン処理" do
      context "アサイン可能なアカウントがある場合" do
        let!(:assignable_member) { create(:account_member, areas: [area]) }
        let(:params) { { task_title: "テスト撮影タスク", area_id: area.id } }

        it "AssignHistoryが作成されること" do
          expect {
            described_class.new.call(params, admin_account)
          }.to change(AssignHistory, :count).by(1)
        end
      end

      context "アサイン可能なアカウントがない場合" do
        let(:params) { { task_title: "テスト撮影タスク", area_id: area.id } }

        it "success?がfalseを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be false
          expect(result.errors).to include("アサイン可能なアカウントがありません")
        end

        it "トランザクションがロールバックされTaskが保存されないこと" do
          expect {
            described_class.new.call(params, admin_account)
          }.not_to change(Task, :count)
        end

        it "トランザクションがロールバックされAssignCycleが作成されないこと" do
          expect {
            described_class.new.call(params, admin_account)
          }.not_to change(AssignCycle, :count)
        end
      end
    end
  end
end
