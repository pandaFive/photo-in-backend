# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::Destroy, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:area) { create(:area) }
    let!(:target_task) { create(:task, area:) }

    let(:valid_params) do
      { id: target_task.id }
    end

    describe "正常系" do
      context "adminユーザーが存在するタスクを削除する場合" do
        it "成功を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.errors).to be_empty
        end

        it "タスクがDBから削除されること" do
          expect {
            described_class.new.call(valid_params, admin)
          }.to change(Task, :count).by(-1)
        end

        it "削除されたタスクが検索できないこと" do
          described_class.new.call(valid_params, admin)

          expect(Task.find_by(id: target_task.id)).to be_nil
        end

        it "レスポンス形式が正しいこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.message).to eq("deleted")
        end
      end
    end

    describe "異常系" do
      context "認証エラーの場合" do
        context "current_accountがnilの場合" do
          it "unauthorizedを返すこと" do
            result = described_class.new.call(valid_params, nil)

            expect(result.success?).to be false
            expect(result.status).to eq(:unauthorized)
            expect(result.errors).to include("認証が必要です")
          end

          it "タスクが削除されないこと" do
            expect {
              described_class.new.call(valid_params, nil)
            }.not_to change(Task, :count)
          end
        end
      end

      context "バリデーションエラーの場合" do
        it "idが空の場合、失敗を返すこと" do
          params = { id: nil }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
          expect(result.errors).not_to be_empty
        end

        it "idが数値でない場合、失敗を返すこと" do
          params = { id: "abc" }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "タスクが削除されないこと" do
          params = { id: nil }
          expect {
            described_class.new.call(params, admin)
          }.not_to change(Task, :count)
        end
      end

      context "権限エラーの場合" do
        context "memberユーザーの場合" do
          it "forbiddenを返すこと" do
            result = described_class.new.call(valid_params, member)

            expect(result.success?).to be false
            expect(result.status).to eq(:forbidden)
            expect(result.errors).to include("権限がありません")
          end

          it "タスクが削除されないこと" do
            expect {
              described_class.new.call(valid_params, member)
            }.not_to change(Task, :count)
          end
        end
      end

      context "タスクが存在しない場合" do
        it "not_foundを返すこと" do
          params = { id: 999999 }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors).to include("タスクが見つかりません")
        end

        it "他のタスクが削除されないこと" do
          params = { id: 999999 }
          expect {
            described_class.new.call(params, admin)
          }.not_to change(Task, :count)
        end
      end
    end

    describe "処理順序の検証" do
      it "認証 → バリデーション → 認可 → 検索 → 削除の順序で処理されること" do
        # 認証エラーはバリデーション前に返される
        result_unauth = described_class.new.call({ id: nil }, nil)
        expect(result_unauth.status).to eq(:unauthorized)

        # バリデーションエラーは認可チェック前に返される
        result_invalid = described_class.new.call({ id: nil }, admin)
        expect(result_invalid.status).to eq(:unprocessable_entity)

        # 認可エラーは存在チェック前に返される（存在しないIDでも403）
        result_forbidden = described_class.new.call({ id: 999999 }, member)
        expect(result_forbidden.status).to eq(:forbidden)

        # 存在しないタスクはnot_foundを返す
        result_not_found = described_class.new.call({ id: 999999 }, admin)
        expect(result_not_found.status).to eq(:not_found)
      end
    end

    describe "Repository DI" do
      it "カスタムRepositoryを受け取れること" do
        mock_repository = instance_double(Services::Tasks::Repository)
        allow(mock_repository).to receive(:find_by_id).with(target_task.id).and_return(target_task)
        allow(mock_repository).to receive(:delete).with(target_task).and_return(true)

        service = described_class.new(repository: mock_repository)
        result = service.call(valid_params, admin)

        expect(result.success?).to be true
        expect(mock_repository).to have_received(:find_by_id).with(target_task.id)
        expect(mock_repository).to have_received(:delete).with(target_task)
      end

      context "削除が失敗した場合" do
        it "unprocessable_entityを返すこと" do
          mock_repository = instance_double(Services::Tasks::Repository)
          allow(mock_repository).to receive(:find_by_id).with(target_task.id).and_return(target_task)
          allow(mock_repository).to receive(:delete).with(target_task).and_return(false)

          service = described_class.new(repository: mock_repository)
          result = service.call(valid_params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
          expect(result.errors).to include("タスクの削除に失敗しました")
        end
      end
    end

    describe "関連データの処理" do
      let!(:assign_cycle) { create(:assign_cycle, task: target_task) }

      it "関連AssignCycleがある場合、conflictを返すこと" do
        result = described_class.new.call(valid_params, admin)

        expect(result.success?).to be false
        expect(result.status).to eq(:conflict)
        expect(result.errors).to include("関連データが存在するため削除できません")
      end

      it "エラー発生時にタスクが削除されないこと" do
        expect {
          described_class.new.call(valid_params, admin)
        }.not_to change(Task, :count)
      end

      it "例外が発生しないこと" do
        expect {
          described_class.new.call(valid_params, admin)
        }.not_to raise_error
      end
    end
  end
end
