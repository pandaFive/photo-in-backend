# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::GetAccountTask, type: :service do
  let(:repository) { instance_double(Services::Tasks::Repository) }
  let(:service) { described_class.new(repository:) }

  describe "#call" do
    let!(:admin) { create(:account) }
    let!(:member) { create(:account_member) }

    context "認証されていない場合" do
      it "unauthorizedを返すこと" do
        result = service.call({ id: "1" }, nil)
        expect(result.success?).to be false
        expect(result.status).to eq(:unauthorized)
        expect(result.errors).to include("認証が必要です")
      end

      it "tasksがnilであること" do
        result = service.call({ id: "1" }, nil)
        expect(result.tasks).to be_nil
      end
    end

    context "Contract検証が失敗した場合" do
      it "unprocessable_entityを返すこと（idが空）" do
        result = service.call({ id: "" }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
      end

      it "unprocessable_entityを返すこと（idがnil）" do
        result = service.call({ id: nil }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
      end

      it "unprocessable_entityを返すこと（idが非数値）" do
        result = service.call({ id: "abc" }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
      end
    end

    context "認可チェック" do
      let(:sample_tasks) { [{ id: 1, title: "タスク1" }] }

      before do
        allow(repository).to receive(:get_account_assign_tasks).and_return(sample_tasks)
      end

      context "管理者の場合" do
        it "自分のタスクを取得できること" do
          result = service.call({ id: admin.id.to_s }, admin)
          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
        end

        it "他人のタスクも取得できること" do
          result = service.call({ id: member.id.to_s }, admin)
          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
        end
      end

      context "一般メンバーの場合" do
        it "自分のタスクを取得できること" do
          result = service.call({ id: member.id.to_s }, member)
          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
        end

        it "他人のタスクは取得できないこと" do
          result = service.call({ id: admin.id.to_s }, member)
          expect(result.success?).to be false
          expect(result.status).to eq(:forbidden)
          expect(result.errors).to include("この操作を行う権限がありません")
        end
      end
    end

    context "正常系" do
      let(:sample_tasks) do
        [
          { id: 1, title: "タスク1", area_name: "エリア1", history_id: 10, assign_cycle_id: 5 },
          { id: 2, title: "タスク2", area_name: "エリア2", history_id: 11, assign_cycle_id: 6 }
        ]
      end

      before do
        allow(repository).to receive(:get_account_assign_tasks).and_return(sample_tasks)
      end

      it "成功を返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "タスク一覧を返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.tasks).to eq(sample_tasks)
      end

      it "repository.get_account_assign_tasksを呼び出すこと" do
        service.call({ id: admin.id.to_s }, admin)
        expect(repository).to have_received(:get_account_assign_tasks).with(admin.id)
      end
    end

    context "データが空の場合" do
      before do
        allow(repository).to receive(:get_account_assign_tasks).and_return([])
      end

      it "成功を返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.success?).to be true
      end

      it "空配列を返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.tasks).to eq([])
      end
    end

    context "データベース接続エラーの場合" do
      before do
        allow(repository).to receive(:get_account_assign_tasks).and_raise(ActiveRecord::ConnectionNotEstablished)
        allow(Rails.logger).to receive(:error)
      end

      it "失敗を返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:service_unavailable)
      end

      it "エラーメッセージを返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.errors).to include("データベース接続に失敗しました。しばらくしてから再試行してください。")
      end

      it "エラーをログに記録すること" do
        service.call({ id: admin.id.to_s }, admin)
        expect(Rails.logger).to have_received(:error).with(hash_including(message: "データベース接続失敗"))
      end
    end

    context "PostgreSQL接続エラーの場合" do
      before do
        allow(repository).to receive(:get_account_assign_tasks).and_raise(PG::ConnectionBad)
        allow(Rails.logger).to receive(:error)
      end

      it "失敗を返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:service_unavailable)
      end

      it "エラーメッセージを返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.errors).to include("データベース接続に失敗しました。しばらくしてから再試行してください。")
      end
    end

    context "データベースクエリエラーの場合" do
      before do
        allow(repository).to receive(:get_account_assign_tasks).and_raise(ActiveRecord::StatementInvalid.new("query error"))
        allow(Rails.logger).to receive(:error)
      end

      it "失敗を返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:internal_server_error)
      end

      it "エラーメッセージを返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.errors).to include("データの取得に失敗しました。")
      end

      it "エラーをログに記録すること" do
        service.call({ id: admin.id.to_s }, admin)
        expect(Rails.logger).to have_received(:error).with(hash_including(message: "データベースクエリ失敗"))
      end
    end

    context "クエリキャンセル（タイムアウト）の場合" do
      before do
        allow(repository).to receive(:get_account_assign_tasks).and_raise(ActiveRecord::QueryCanceled)
        allow(Rails.logger).to receive(:error)
      end

      it "失敗を返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:internal_server_error)
      end

      it "エラーメッセージを返すこと" do
        result = service.call({ id: admin.id.to_s }, admin)
        expect(result.errors).to include("データの取得に失敗しました。")
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
