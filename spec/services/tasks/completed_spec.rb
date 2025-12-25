# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::Completed, type: :service do
  let!(:admin) { create(:account, role: "admin") }
  let!(:member) { create(:account_member) }
  let!(:other_member) { create(:account_member) }
  let!(:area) { create(:area) }
  let!(:task) { create(:task, area:) }

  # タスクにメンバーを担当者として割り当てる
  def assign_to_member(task, account, completed: false)
    cycle = create(:assign_cycle, task:, is_active: true)
    create(:assign_history, account:, assign_cycle: cycle, completed:, ng: false)
  end

  describe "#call" do
    describe "正常系" do
      context "管理者がタスクを完了する場合" do
        let!(:assign_history) { assign_to_member(task, member) }

        it "success?がtrueを返すこと" do
          result = described_class.new.call({ id: assign_history.id }, admin)
          expect(result.success?).to be true
        end

        it "statusが:okであること" do
          result = described_class.new.call({ id: assign_history.id }, admin)
          expect(result.status).to eq(:ok)
        end

        it "messageが'change completed'であること" do
          result = described_class.new.call({ id: assign_history.id }, admin)
          expect(result.message).to eq("change completed")
        end

        it "errorsが空であること" do
          result = described_class.new.call({ id: assign_history.id }, admin)
          expect(result.errors).to be_empty
        end

        it "AssignHistoryのcompletedがtrueに更新されること" do
          described_class.new.call({ id: assign_history.id }, admin)
          expect(assign_history.reload.completed).to be true
        end

        it "AssignHistoryのcompleted_atが設定されること" do
          described_class.new.call({ id: assign_history.id }, admin)
          expect(assign_history.reload.completed_at).not_to be_nil
        end

        it "AssignCycleのis_activeがfalseに更新されること" do
          described_class.new.call({ id: assign_history.id }, admin)
          expect(assign_history.assign_cycle.reload.is_active).to be false
        end
      end

      context "担当メンバーが自分のタスクを完了する場合" do
        let!(:assign_history) { assign_to_member(task, member) }

        it "success?がtrueを返すこと" do
          result = described_class.new.call({ id: assign_history.id }, member)
          expect(result.success?).to be true
        end

        it "AssignHistoryのcompletedがtrueに更新されること" do
          described_class.new.call({ id: assign_history.id }, member)
          expect(assign_history.reload.completed).to be true
        end
      end

      context "idが文字列の場合" do
        let!(:assign_history) { assign_to_member(task, member) }

        it "success?がtrueを返すこと" do
          result = described_class.new.call({ id: assign_history.id.to_s }, admin)
          expect(result.success?).to be true
        end
      end
    end

    describe "異常系" do
      context "認証エラー" do
        let!(:assign_history) { assign_to_member(task, member) }

        context "current_accountがnilの場合" do
          it "success?がfalseを返すこと" do
            result = described_class.new.call({ id: assign_history.id }, nil)
            expect(result.success?).to be false
          end

          it "statusが:unauthorizedであること" do
            result = described_class.new.call({ id: assign_history.id }, nil)
            expect(result.status).to eq(:unauthorized)
          end

          it "認証エラーメッセージを返すこと" do
            result = described_class.new.call({ id: assign_history.id }, nil)
            expect(result.errors).to include("認証が必要です")
          end

          it "AssignHistoryが更新されないこと" do
            described_class.new.call({ id: assign_history.id }, nil)
            expect(assign_history.reload.completed).to be false
          end
        end
      end

      context "バリデーションエラー" do
        context "idが空の場合" do
          it "success?がfalseを返すこと" do
            result = described_class.new.call({ id: "" }, admin)
            expect(result.success?).to be false
          end

          it "statusが:unprocessable_entityであること" do
            result = described_class.new.call({ id: "" }, admin)
            expect(result.status).to eq(:unprocessable_entity)
          end
        end

        context "idがnilの場合" do
          it "success?がfalseを返すこと" do
            result = described_class.new.call({ id: nil }, admin)
            expect(result.success?).to be false
          end
        end

        context "idが非数値の場合" do
          it "success?がfalseを返すこと" do
            result = described_class.new.call({ id: "abc" }, admin)
            expect(result.success?).to be false
          end

          it "statusが:unprocessable_entityであること" do
            result = described_class.new.call({ id: "abc" }, admin)
            expect(result.status).to eq(:unprocessable_entity)
          end
        end
      end

      context "AssignHistoryが存在しない場合" do
        it "success?がfalseを返すこと" do
          result = described_class.new.call({ id: 999999 }, admin)
          expect(result.success?).to be false
        end

        it "statusが:not_foundであること" do
          result = described_class.new.call({ id: 999999 }, admin)
          expect(result.status).to eq(:not_found)
        end

        it "エラーメッセージを返すこと" do
          result = described_class.new.call({ id: 999999 }, admin)
          expect(result.errors).to include("担当履歴が見つかりません")
        end
      end

      context "認可エラー" do
        let!(:assign_history) { assign_to_member(task, member) }

        context "非担当メンバーが完了しようとする場合" do
          it "success?がfalseを返すこと" do
            result = described_class.new.call({ id: assign_history.id }, other_member)
            expect(result.success?).to be false
          end

          it "statusが:forbiddenであること" do
            result = described_class.new.call({ id: assign_history.id }, other_member)
            expect(result.status).to eq(:forbidden)
          end

          it "権限エラーメッセージを返すこと" do
            result = described_class.new.call({ id: assign_history.id }, other_member)
            expect(result.errors).to include("権限がありません")
          end

          it "AssignHistoryが更新されないこと" do
            described_class.new.call({ id: assign_history.id }, other_member)
            expect(assign_history.reload.completed).to be false
          end
        end
      end

      context "既に完了済みの場合" do
        let!(:assign_history) { assign_to_member(task, member, completed: true) }

        it "success?がfalseを返すこと" do
          result = described_class.new.call({ id: assign_history.id }, admin)
          expect(result.success?).to be false
        end

        it "statusが:unprocessable_entityであること" do
          result = described_class.new.call({ id: assign_history.id }, admin)
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "エラーメッセージを返すこと" do
          result = described_class.new.call({ id: assign_history.id }, admin)
          expect(result.errors).to include("既に完了しています")
        end
      end

      context "ロック例外が発生する場合" do
        let!(:assign_history) { assign_to_member(task, member) }

        context "Deadlockedが発生する場合" do
          before do
            allow(AssignHistory).to receive(:transaction).and_raise(ActiveRecord::Deadlocked.new("deadlock detected"))
          end

          it "success?がfalseを返すこと" do
            result = described_class.new.call({ id: assign_history.id }, admin)
            expect(result.success?).to be false
          end

          it "statusが:service_unavailableであること" do
            result = described_class.new.call({ id: assign_history.id }, admin)
            expect(result.status).to eq(:service_unavailable)
          end

          it "混雑エラーメッセージを返すこと" do
            result = described_class.new.call({ id: assign_history.id }, admin)
            expect(result.errors).to include("サーバーが混雑しています。しばらくしてから再試行してください。")
          end
        end

        context "LockWaitTimeoutが発生する場合" do
          before do
            allow(AssignHistory).to receive(:transaction).and_raise(ActiveRecord::LockWaitTimeout.new("lock wait timeout"))
          end

          it "success?がfalseを返すこと" do
            result = described_class.new.call({ id: assign_history.id }, admin)
            expect(result.success?).to be false
          end

          it "statusが:service_unavailableであること" do
            result = described_class.new.call({ id: assign_history.id }, admin)
            expect(result.status).to eq(:service_unavailable)
          end

          it "混雑エラーメッセージを返すこと" do
            result = described_class.new.call({ id: assign_history.id }, admin)
            expect(result.errors).to include("サーバーが混雑しています。しばらくしてから再試行してください。")
          end
        end
      end

      context "保存エラーが発生する場合" do
        let!(:assign_history) { assign_to_member(task, member) }
        let(:mock_repository) { instance_double(Services::Tasks::Repository) }
        let(:service) { described_class.new(repository: mock_repository) }

        before do
          allow(mock_repository).to receive(:find_assign_history_with_lock).with(assign_history.id).and_return(assign_history)
          allow(mock_repository).to receive(:complete_assign_history).with(assign_history).and_raise(ActiveRecord::RecordInvalid.new(assign_history))
        end

        it "success?がfalseを返すこと" do
          result = service.call({ id: assign_history.id }, admin)
          expect(result.success?).to be false
        end

        it "statusが:unprocessable_entityであること" do
          result = service.call({ id: assign_history.id }, admin)
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "保存失敗エラーメッセージを返すこと" do
          result = service.call({ id: assign_history.id }, admin)
          expect(result.errors).to include("タスクの完了処理に失敗しました。")
        end
      end

      context "deactivate_cycleが失敗した場合のトランザクションロールバック" do
        let!(:assign_history) { assign_to_member(task, member) }

        it "AssignHistoryの変更がロールバックされること" do
          # deactivate_cycleで例外を発生させる
          allow_any_instance_of(AssignCycle).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(task))

          expect {
            described_class.new.call({ id: assign_history.id }, admin)
          }.not_to change { assign_history.reload.completed }
        end

        it "AssignCycleがアクティブのままであること" do
          allow_any_instance_of(AssignCycle).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(task))

          expect {
            described_class.new.call({ id: assign_history.id }, admin)
          }.not_to change { assign_history.assign_cycle.reload.is_active }
        end
      end
    end

    describe "処理順序の検証" do
      let!(:assign_history) { assign_to_member(task, member) }

      it "認証 → バリデーション → 取得 → 認可 → 完了チェック → 実行 の順序で処理されること" do
        # 認証エラーはバリデーション前に返される
        result_unauth = described_class.new.call({ id: nil }, nil)
        expect(result_unauth.status).to eq(:unauthorized)

        # バリデーションエラーは取得前に返される
        result_invalid = described_class.new.call({ id: nil }, admin)
        expect(result_invalid.status).to eq(:unprocessable_entity)

        # 存在しないIDはnot_foundを返す（認可チェックより先）
        result_not_found = described_class.new.call({ id: 999999 }, other_member)
        expect(result_not_found.status).to eq(:not_found)

        # 認可エラー
        result_forbidden = described_class.new.call({ id: assign_history.id }, other_member)
        expect(result_forbidden.status).to eq(:forbidden)
      end
    end

    describe "依存性注入" do
      let!(:assign_cycle) { create(:assign_cycle, task:, is_active: true) }
      let!(:assign_history) { create(:assign_history, account: member, assign_cycle:, completed: false, ng: false) }

      context "カスタムリポジトリを使用する場合" do
        let(:mock_repository) { instance_double(Services::Tasks::Repository) }
        let(:service) { described_class.new(repository: mock_repository) }
        let(:params) { { id: assign_history.id } }

        before do
          allow(mock_repository).to receive(:find_assign_history_with_lock).with(assign_history.id).and_return(assign_history)
          allow(mock_repository).to receive(:complete_assign_history).with(assign_history).and_return(true)
          allow(mock_repository).to receive(:deactivate_cycle).with(assign_cycle).and_return(true)
        end

        it "指定されたリポジトリのfind_assign_history_with_lockを呼び出すこと" do
          service.call(params, admin)
          expect(mock_repository).to have_received(:find_assign_history_with_lock).with(assign_history.id)
        end

        it "指定されたリポジトリのcomplete_assign_historyを呼び出すこと" do
          service.call(params, admin)
          expect(mock_repository).to have_received(:complete_assign_history).with(assign_history)
        end

        it "指定されたリポジトリのdeactivate_cycleを呼び出すこと" do
          service.call(params, admin)
          expect(mock_repository).to have_received(:deactivate_cycle).with(assign_cycle)
        end
      end
    end
  end
end
