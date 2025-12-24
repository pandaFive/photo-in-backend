# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::Update, type: :service do
  let(:admin_account) { create(:account) }
  let(:member_account) { create(:account_member) }
  let(:other_member) { create(:account_member) }
  let!(:area) { create(:area, name: "テストエリア") }
  let!(:task) { create(:task, area:, task_title: "元のタイトル") }

  # タスクにメンバーを担当者として割り当てる
  def assign_to_member(task, account)
    cycle = create(:assign_cycle, task_id: task.id, is_active: true)
    create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id)
  end

  describe "#call" do
    describe "正常系" do
      context "管理者がタスクを更新する場合" do
        let(:params) { { id: task.id.to_s, task_title: "更新後タイトル" } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
        end

        it "taskに更新されたタスクを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.task.task_title).to eq("更新後タイトル")
        end

        it "statusが:okであること" do
          result = described_class.new.call(params, admin_account)
          expect(result.status).to eq(:ok)
        end

        it "errorsが空であること" do
          result = described_class.new.call(params, admin_account)
          expect(result.errors).to be_empty
        end

        it "DBが更新されていること" do
          described_class.new.call(params, admin_account)
          task.reload
          expect(task.task_title).to eq("更新後タイトル")
        end
      end

      context "担当メンバーが自分のタスクを更新する場合" do
        let(:params) { { id: task.id.to_s, task_title: "担当者による更新" } }

        before do
          assign_to_member(task, member_account)
        end

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, member_account)
          expect(result.success?).to be true
        end

        it "taskを返すこと" do
          result = described_class.new.call(params, member_account)
          expect(result.task.task_title).to eq("担当者による更新")
        end
      end

      context "task_titleなしで更新する場合（属性なし）" do
        let(:params) { { id: task.id.to_s } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
        end

        it "タスクが変更されないこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.task.task_title).to eq("元のタイトル")
        end
      end

      context "idが整数の場合" do
        let(:params) { { id: task.id, task_title: "整数ID更新" } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
        end
      end
    end

    describe "異常系" do
      context "認証エラー" do
        context "current_accountがnilの場合" do
          let(:params) { { id: task.id.to_s, task_title: "更新" } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, nil)
            expect(result.success?).to be false
          end

          it "statusが:unauthorizedであること" do
            result = described_class.new.call(params, nil)
            expect(result.status).to eq(:unauthorized)
          end

          it "認証エラーメッセージを返すこと" do
            result = described_class.new.call(params, nil)
            expect(result.errors).to include("認証が必要です")
          end
        end
      end

      context "バリデーションエラー" do
        context "idが空の場合" do
          let(:params) { { id: "", task_title: "更新" } }

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
            expect(result.errors).to include("Id can't be blank")
          end
        end

        context "task_titleが257文字を超える場合" do
          let(:params) { { id: task.id.to_s, task_title: "あ" * 257 } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, admin_account)
            expect(result.success?).to be false
          end

          it "statusが:unprocessable_entityであること" do
            result = described_class.new.call(params, admin_account)
            expect(result.status).to eq(:unprocessable_entity)
          end
        end
      end

      context "タスクが存在しない場合" do
        let(:params) { { id: "999999", task_title: "更新" } }

        it "success?がfalseを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be false
        end

        it "statusが:not_foundであること" do
          result = described_class.new.call(params, admin_account)
          expect(result.status).to eq(:not_found)
        end

        it "エラーメッセージを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.errors).to include("タスクが見つかりません")
        end
      end

      context "認可エラー" do
        context "非担当メンバーが更新しようとする場合" do
          let(:params) { { id: task.id.to_s, task_title: "不正な更新" } }

          before do
            assign_to_member(task, member_account)
          end

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, other_member)
            expect(result.success?).to be false
          end

          it "statusが:forbiddenであること" do
            result = described_class.new.call(params, other_member)
            expect(result.status).to eq(:forbidden)
          end

          it "権限エラーメッセージを返すこと" do
            result = described_class.new.call(params, other_member)
            expect(result.errors).to include("権限がありません")
          end
        end

        context "割り当てなしタスクをメンバーが更新しようとする場合" do
          let(:params) { { id: task.id.to_s, task_title: "不正な更新" } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, member_account)
            expect(result.success?).to be false
          end

          it "statusが:forbiddenであること" do
            result = described_class.new.call(params, member_account)
            expect(result.status).to eq(:forbidden)
          end
        end
      end

      context "モデルバリデーションエラー" do
        let(:params) { { id: task.id.to_s, task_title: "" } }

        # task_titleがpresenceのため、空文字列は Contract では許可されるが
        # normalized_attributes に含まれないため、更新は実行されない
        it "task_titleが空の場合は更新されないこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
          expect(result.task.task_title).to eq("元のタイトル")
        end
      end
    end

    describe "依存性注入" do
      context "カスタムリポジトリを使用する場合" do
        let(:mock_repository) { instance_double(Services::Tasks::Repository) }
        let(:service) { described_class.new(repository: mock_repository) }
        let(:params) { { id: "1", task_title: "更新" } }

        before do
          allow(mock_repository).to receive(:find_by_id_with_lock).with(1).and_return(task)
          allow(mock_repository).to receive(:update).with(task, { task_title: "更新" }).and_return(true)
        end

        it "指定されたリポジトリのfind_by_id_with_lockを呼び出すこと" do
          service.call(params, admin_account)
          expect(mock_repository).to have_received(:find_by_id_with_lock).with(1)
        end

        it "指定されたリポジトリのupdateを呼び出すこと" do
          service.call(params, admin_account)
          expect(mock_repository).to have_received(:update).with(task, { task_title: "更新" })
        end

        it "リポジトリがnilを返した場合はnot_foundを返すこと" do
          allow(mock_repository).to receive(:find_by_id_with_lock).with(1).and_return(nil)
          result = service.call(params, admin_account)
          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
        end

        it "リポジトリのupdateがfalseを返した場合はunprocessable_entityを返すこと" do
          allow(mock_repository).to receive(:update).with(task, { task_title: "更新" }).and_return(false)
          allow(task).to receive_message_chain(:errors, :full_messages).and_return(["更新に失敗しました"])
          result = service.call(params, admin_account)
          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end
      end
    end
  end
end
