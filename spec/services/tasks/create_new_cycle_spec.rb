# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::CreateNewCycle, type: :service do
  let(:repository) { instance_double(Services::Tasks::Repository) }
  let(:service) { described_class.new(repository:) }

  describe "#call" do
    let!(:admin) { create(:account) }
    let!(:member) { create(:account_member) }
    let!(:area) { create(:area) }
    let!(:task) { create(:task, area:) }

    context "認証されていない場合" do
      let(:params) { { id: task.id.to_s } }

      it "unauthorizedを返すこと" do
        result = service.call(params, nil)
        expect(result.success?).to be false
        expect(result.status).to eq(:unauthorized)
        expect(result.errors).to include("認証が必要です")
      end
    end

    context "管理者ではない場合" do
      let(:params) { { id: task.id.to_s } }

      it "forbiddenを返すこと" do
        result = service.call(params, member)
        expect(result.success?).to be false
        expect(result.status).to eq(:forbidden)
        expect(result.errors).to include("権限がありません")
      end
    end

    context "Contract検証に失敗した場合" do
      let(:params) { { id: "invalid" } }

      it "unprocessable_entityを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
      end

      it "Contractのエラーメッセージを返すこと" do
        result = service.call(params, admin)
        expect(result.errors).to include("Id is not a number")
      end
    end

    context "Taskが存在しない場合" do
      let(:params) { { id: "999999" } }

      before do
        allow(repository).to receive(:find_by_id_with_lock).with(999999).and_return(nil)
      end

      it "not_foundを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:not_found)
        expect(result.errors).to include("タスクが見つかりません")
      end
    end

    context "正常にサイクルを作成して割り当てが成功した場合" do
      let(:params) { { id: task.id.to_s } }
      let(:new_cycle) { instance_double(AssignCycle, id: 100) }
      let(:assign_result) { instance_double(AssignHistory, account_id: member.id) }

      before do
        allow(repository).to receive(:find_by_id_with_lock).with(task.id).and_return(task)
        allow(repository).to receive(:deactivate_all_cycles).with(task).and_return(0)
        allow(repository).to receive(:create_cycle).with(task).and_return(new_cycle)
        allow(new_cycle).to receive(:assign).and_return(assign_result)
      end

      it "成功を返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "taskを返すこと" do
        result = service.call(params, admin)
        expect(result.task).to eq(task)
      end

      it "deactivate_all_cyclesを呼び出すこと" do
        service.call(params, admin)
        expect(repository).to have_received(:deactivate_all_cycles).with(task)
      end

      it "create_cycleを呼び出すこと" do
        service.call(params, admin)
        expect(repository).to have_received(:create_cycle).with(task)
      end

      it "assignを呼び出すこと" do
        service.call(params, admin)
        expect(new_cycle).to have_received(:assign)
      end
    end

    context "サイクルは作成されたが割り当てが失敗した場合" do
      let(:params) { { id: task.id.to_s } }
      let(:new_cycle) { instance_double(AssignCycle, id: 100) }

      before do
        allow(repository).to receive(:find_by_id_with_lock).with(task.id).and_return(task)
        allow(repository).to receive(:deactivate_all_cycles).with(task).and_return(0)
        allow(repository).to receive(:create_cycle).with(task).and_return(new_cycle)
        allow(new_cycle).to receive(:assign).and_return(false)
      end

      it "失敗を返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
      end

      it "エラーメッセージを返すこと" do
        result = service.call(params, admin)
        expect(result.errors).to include("割り当て可能なメンバーがいません")
      end

      it "taskを返すこと（サイクルは作成されているため）" do
        result = service.call(params, admin)
        expect(result.task).to eq(task)
      end
    end

    context "既存のサイクルがある場合" do
      let(:params) { { id: task.id.to_s } }
      let!(:existing_cycle) { create(:assign_cycle, task:, is_active: true) }
      let(:new_cycle) { instance_double(AssignCycle, id: 100) }
      let(:assign_result) { instance_double(AssignHistory, account_id: member.id) }

      before do
        allow(repository).to receive(:find_by_id_with_lock).with(task.id).and_return(task)
        allow(repository).to receive(:deactivate_all_cycles).with(task).and_return(1)
        allow(repository).to receive(:create_cycle).with(task).and_return(new_cycle)
        allow(new_cycle).to receive(:assign).and_return(assign_result)
      end

      it "既存のサイクルを非アクティブ化すること" do
        service.call(params, admin)
        expect(repository).to have_received(:deactivate_all_cycles).with(task)
      end
    end

    context "Deadlocked例外が発生した場合" do
      let(:params) { { id: task.id.to_s } }

      before do
        allow(repository).to receive(:find_by_id_with_lock).and_raise(ActiveRecord::Deadlocked.new("Deadlock"))
      end

      it "service_unavailableを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:service_unavailable)
        expect(result.errors).to include("サーバーが混雑しています")
      end
    end

    context "LockWaitTimeout例外が発生した場合" do
      let(:params) { { id: task.id.to_s } }

      before do
        allow(repository).to receive(:find_by_id_with_lock).and_raise(ActiveRecord::LockWaitTimeout.new("Timeout"))
      end

      it "service_unavailableを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:service_unavailable)
      end
    end

    context "RecordInvalid例外が発生した場合" do
      let(:params) { { id: task.id.to_s } }

      before do
        allow(repository).to receive(:find_by_id_with_lock).with(task.id).and_return(task)
        allow(repository).to receive(:deactivate_all_cycles).and_raise(ActiveRecord::RecordInvalid.new(task))
      end

      it "unprocessable_entityを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.errors).to include("サイクル作成に失敗しました")
      end
    end
  end

  describe "依存性注入" do
    it "デフォルトでRepositoryを使用すること" do
      service = described_class.new
      expect(service.instance_variable_get(:@repository)).to be_a(Services::Tasks::Repository)
    end

    it "カスタムRepositoryを注入できること" do
      custom_repo = instance_double(Services::Tasks::Repository)
      service = described_class.new(repository: custom_repo)
      expect(service.instance_variable_get(:@repository)).to eq(custom_repo)
    end
  end
end
