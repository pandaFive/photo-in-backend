# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::Ng, type: :service do
  let(:repository) { instance_double(Services::Tasks::Repository) }
  let(:service) { described_class.new(repository:) }

  describe "#call" do
    let!(:admin) { create(:account) }
    let!(:member) { create(:account_member) }
    let!(:other_member) { create(:account_member) }
    let!(:area) { create(:area) }
    let!(:task) { create(:task, area:) }
    let!(:assign_cycle) { create(:assign_cycle, task:, is_active: true) }
    let!(:assign_history) { create(:assign_history, assign_cycle:, account: member, ng: false, completed: false) }

    before do
      # タスクの現在の担当者として設定
      allow(task).to receive(:current_assignee?).with(admin).and_return(false)
      allow(task).to receive(:current_assignee?).with(member).and_return(true)
      allow(task).to receive(:current_assignee?).with(other_member).and_return(false)
    end

    context "認証されていない場合" do
      let(:params) { { id: assign_history.id.to_s } }

      it "unauthorizedを返すこと" do
        result = service.call(params, nil)
        expect(result.success?).to be false
        expect(result.status).to eq(:unauthorized)
        expect(result.errors).to include("認証が必要です")
      end
    end

    context "Contract検証に失敗した場合" do
      let(:params) { { id: "invalid" } }

      it "unprocessable_entityを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
      end
    end

    context "AssignHistoryが存在しない場合" do
      let(:params) { { id: "999999" } }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).with(999999).and_return(nil)
      end

      it "not_foundを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:not_found)
        expect(result.errors).to include("担当履歴が見つかりません")
      end
    end

    context "権限がない場合（非担当メンバー）" do
      let(:params) { { id: assign_history.id.to_s } }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).with(assign_history.id).and_return(assign_history)
      end

      it "forbiddenを返すこと" do
        result = service.call(params, other_member)
        expect(result.success?).to be false
        expect(result.status).to eq(:forbidden)
        expect(result.errors).to include("権限がありません")
      end
    end

    context "既にNGの場合" do
      let(:params) { { id: assign_history.id.to_s } }
      let!(:ng_history) { create(:assign_history, assign_cycle:, account: member, ng: true, completed: false) }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).with(ng_history.id).and_return(ng_history)
      end

      it "unprocessable_entityを返すこと" do
        result = service.call({ id: ng_history.id.to_s }, member)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.errors).to include("既にNGです")
      end
    end

    context "既に完了している場合" do
      let(:params) { { id: assign_history.id.to_s } }
      let!(:completed_history) { create(:assign_history, assign_cycle:, account: member, ng: false, completed: true) }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).with(completed_history.id).and_return(completed_history)
      end

      it "unprocessable_entityを返すこと" do
        result = service.call({ id: completed_history.id.to_s }, member)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.errors).to include("既に完了しています")
      end
    end

    context "管理者がNG操作する場合" do
      let(:params) { { id: assign_history.id.to_s } }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).with(assign_history.id).and_return(assign_history)
        allow(repository).to receive(:mark_ng).with(assign_history).and_return(true)
        allow(assign_cycle).to receive(:assign).and_return(true)
      end

      it "成功を返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "mark_ngを呼び出すこと" do
        service.call(params, admin)
        expect(repository).to have_received(:mark_ng).with(assign_history)
      end
    end

    context "担当者が自分のタスクをNG操作する場合" do
      let(:params) { { id: assign_history.id.to_s } }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).with(assign_history.id).and_return(assign_history)
        allow(repository).to receive(:mark_ng).with(assign_history).and_return(true)
        allow(assign_cycle).to receive(:assign).and_return(true)
      end

      it "成功を返すこと" do
        result = service.call(params, member)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end
    end

    context "再割り当てが成功した場合" do
      let(:params) { { id: assign_history.id.to_s } }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).with(assign_history.id).and_return(assign_history)
        allow(repository).to receive(:mark_ng).with(assign_history).and_return(true)
        allow(assign_cycle).to receive(:assign).and_return(true)
      end

      it "message が 'complete' を返すこと" do
        result = service.call(params, admin)
        expect(result.message).to eq("complete")
      end

      it "assign が呼び出されること" do
        service.call(params, admin)
        expect(assign_cycle).to have_received(:assign)
      end
    end

    context "再割り当てが失敗した場合（適格者なし）" do
      let(:params) { { id: assign_history.id.to_s } }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).with(assign_history.id).and_return(assign_history)
        allow(repository).to receive(:mark_ng).with(assign_history).and_return(true)
        allow(assign_cycle).to receive(:assign).and_return(false)
      end

      it "成功を返すこと（NGマーク自体は成功）" do
        result = service.call(params, admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "message が 'failed' を返すこと" do
        result = service.call(params, admin)
        expect(result.message).to eq("failed")
      end
    end

    context "Deadlocked例外が発生した場合" do
      let(:params) { { id: assign_history.id.to_s } }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).and_raise(ActiveRecord::Deadlocked.new("Deadlock"))
      end

      it "service_unavailableを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:service_unavailable)
        expect(result.errors).to include("サーバーが混雑しています。しばらくしてから再試行してください。")
      end
    end

    context "LockWaitTimeout例外が発生した場合" do
      let(:params) { { id: assign_history.id.to_s } }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).and_raise(ActiveRecord::LockWaitTimeout.new("Timeout"))
      end

      it "service_unavailableを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:service_unavailable)
      end
    end

    context "RecordInvalid例外が発生した場合" do
      let(:params) { { id: assign_history.id.to_s } }

      before do
        allow(repository).to receive(:find_assign_history_with_lock).with(assign_history.id).and_return(assign_history)
        allow(repository).to receive(:mark_ng).and_raise(ActiveRecord::RecordInvalid.new(assign_history))
      end

      it "unprocessable_entityを返すこと" do
        result = service.call(params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.errors).to include("NG処理に失敗しました。")
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
