# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Assigns::CycleCreate, type: :service do
  let(:repository) { instance_double(Services::Assigns::Repository) }
  let(:service) { described_class.new(repository:) }

  describe "#call" do
    let!(:admin) { create(:account) }
    let!(:member) { create(:account_member) }
    let!(:area) { create(:area) }
    let!(:task) { create(:task, area:) }

    let(:valid_params) { { assign_cycle: { task_id: task.id.to_s } } }

    context "認証されていない場合" do
      it "unauthorizedを返すこと" do
        result = service.call(valid_params, nil)
        expect(result.success?).to be false
        expect(result.status).to eq(:unauthorized)
        expect(result.errors).to include("認証が必要です")
      end
    end

    context "管理者ではない場合" do
      it "forbiddenを返すこと" do
        result = service.call(valid_params, member)
        expect(result.success?).to be false
        expect(result.status).to eq(:forbidden)
        expect(result.errors).to include("権限がありません")
      end
    end

    context "Contract検証に失敗した場合" do
      let(:invalid_params) { { assign_cycle: { task_id: "invalid" } } }

      it "unprocessable_entityを返すこと" do
        result = service.call(invalid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
      end

      it "Contractのエラーメッセージを返すこと" do
        result = service.call(invalid_params, admin)
        expect(result.errors.first).to include("タスクIDは正の整数である必要があります")
      end
    end

    context "task_idがない場合" do
      let(:empty_params) { { assign_cycle: { task_id: "" } } }

      it "unprocessable_entityを返すこと" do
        result = service.call(empty_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.errors.first).to include("タスクIDは必須です")
      end
    end

    context "Taskが存在しない場合" do
      let(:not_found_params) { { assign_cycle: { task_id: "999999" } } }

      before do
        allow(repository).to receive(:find_task_with_lock).with(999999).and_return(nil)
      end

      it "not_foundを返すこと" do
        result = service.call(not_found_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:not_found)
        expect(result.errors).to include("タスクが見つかりません")
      end
    end

    context "正常にサイクルを作成して割り当てが成功した場合" do
      let(:new_cycle) { instance_double(AssignCycle, id: 100, task_id: task.id, is_active: true) }
      let(:assign_result) { instance_double(AssignHistory, account_id: member.id) }

      before do
        allow(repository).to receive(:find_task_with_lock).with(task.id).and_return(task)
        allow(repository).to receive(:deactivate_all_cycles).with(task).and_return(0)
        allow(repository).to receive(:create_cycle).with(task).and_return(new_cycle)
        allow(new_cycle).to receive(:assign).and_return(assign_result)
      end

      it "成功を返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:created)
      end

      it "cycleを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.cycle).to eq(new_cycle)
      end

      it "deactivate_all_cyclesを呼び出すこと" do
        service.call(valid_params, admin)
        expect(repository).to have_received(:deactivate_all_cycles).with(task)
      end

      it "create_cycleを呼び出すこと" do
        service.call(valid_params, admin)
        expect(repository).to have_received(:create_cycle).with(task)
      end

      it "assignを呼び出すこと" do
        service.call(valid_params, admin)
        expect(new_cycle).to have_received(:assign)
      end
    end

    context "assign_cycleネストなしのパラメータでも正常に動作すること" do
      let(:flat_params) { { task_id: task.id.to_s } }
      let(:new_cycle) { instance_double(AssignCycle, id: 100, task_id: task.id, is_active: true) }
      let(:assign_result) { instance_double(AssignHistory, account_id: member.id) }

      before do
        allow(repository).to receive(:find_task_with_lock).with(task.id).and_return(task)
        allow(repository).to receive(:deactivate_all_cycles).with(task).and_return(0)
        allow(repository).to receive(:create_cycle).with(task).and_return(new_cycle)
        allow(new_cycle).to receive(:assign).and_return(assign_result)
      end

      it "成功を返すこと" do
        result = service.call(flat_params, admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:created)
      end
    end

    context "サイクルは作成されたが割り当てが失敗した場合" do
      let(:new_cycle) { instance_double(AssignCycle, id: 100) }

      before do
        allow(repository).to receive(:find_task_with_lock).with(task.id).and_return(task)
        allow(repository).to receive(:deactivate_all_cycles).with(task).and_return(0)
        allow(repository).to receive(:create_cycle).with(task).and_return(new_cycle)
        allow(new_cycle).to receive(:assign).and_return(false)
      end

      it "失敗を返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
      end

      it "エラーメッセージを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.errors).to include("割り当て可能なメンバーがいません")
      end

      it "cycleがnilであること（トランザクションがロールバックされるため）" do
        result = service.call(valid_params, admin)
        expect(result.cycle).to be_nil
      end
    end

    context "既存のサイクルがある場合" do
      let!(:existing_cycle) { create(:assign_cycle, task:, is_active: true) }
      let(:new_cycle) { instance_double(AssignCycle, id: 100, task_id: task.id, is_active: true) }
      let(:assign_result) { instance_double(AssignHistory, account_id: member.id) }

      before do
        allow(repository).to receive(:find_task_with_lock).with(task.id).and_return(task)
        allow(repository).to receive(:deactivate_all_cycles).with(task).and_return(1)
        allow(repository).to receive(:create_cycle).with(task).and_return(new_cycle)
        allow(new_cycle).to receive(:assign).and_return(assign_result)
      end

      it "既存のサイクルを非アクティブ化すること" do
        service.call(valid_params, admin)
        expect(repository).to have_received(:deactivate_all_cycles).with(task)
      end
    end

    context "Deadlocked例外が発生した場合" do
      before do
        allow(repository).to receive(:find_task_with_lock).and_raise(ActiveRecord::Deadlocked.new("Deadlock"))
      end

      it "service_unavailableを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:service_unavailable)
        expect(result.errors.first).to include("混雑")
      end
    end

    context "LockWaitTimeout例外が発生した場合" do
      before do
        allow(repository).to receive(:find_task_with_lock).and_raise(ActiveRecord::LockWaitTimeout.new("Timeout"))
      end

      it "service_unavailableを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:service_unavailable)
      end
    end

    context "RecordInvalid例外が発生した場合" do
      before do
        allow(repository).to receive(:find_task_with_lock).with(task.id).and_return(task)
        allow(repository).to receive(:deactivate_all_cycles).and_raise(ActiveRecord::RecordInvalid.new(task))
      end

      it "unprocessable_entityを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.errors.first).to include("サイクル作成または割り当てに失敗しました")
      end
    end

    context "StatementInvalid例外が発生した場合" do
      before do
        allow(repository).to receive(:find_task_with_lock).and_raise(ActiveRecord::StatementInvalid.new("DB Error"))
      end

      it "internal_server_errorを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:internal_server_error)
        expect(result.errors).to include("データベースエラーが発生しました")
      end
    end
  end

  describe "依存性注入" do
    it "デフォルトでRepositoryを使用すること" do
      service = described_class.new
      expect(service.instance_variable_get(:@repository)).to be_a(Services::Assigns::Repository)
    end

    it "カスタムRepositoryを注入できること" do
      custom_repo = instance_double(Services::Assigns::Repository)
      service = described_class.new(repository: custom_repo)
      expect(service.instance_variable_get(:@repository)).to eq(custom_repo)
    end
  end
end
