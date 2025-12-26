# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Comments::Create, type: :model do
  let(:admin) { create(:account, role: "admin") }
  let(:member) { create(:account_member) }
  let(:area) { create(:area) }
  let(:task) { create(:task, area:) }

  describe "#call" do
    context "認証されていない場合" do
      it "unauthorizedを返すこと" do
        result = described_class.new.call({ comment: { content: "テスト", task_id: task.id } }, nil)
        expect(result.success?).to be false
        expect(result.status).to eq :unauthorized
        expect(result.errors).to include("認証が必要です")
      end
    end

    context "バリデーションエラーの場合" do
      it "contentがnilの場合、unprocessable_entityを返すこと" do
        result = described_class.new.call({ comment: { content: nil, task_id: task.id } }, member)
        expect(result.success?).to be false
        expect(result.status).to eq :unprocessable_entity
      end

      it "task_idがnilの場合、unprocessable_entityを返すこと" do
        result = described_class.new.call({ comment: { content: "テスト", task_id: nil } }, member)
        expect(result.success?).to be false
        expect(result.status).to eq :unprocessable_entity
      end
    end

    context "タスクが存在しない場合" do
      it "not_foundを返すこと" do
        result = described_class.new.call({ comment: { content: "テスト", task_id: 999999 } }, member)
        expect(result.success?).to be false
        expect(result.status).to eq :not_found
      end
    end

    context "有効なパラメータの場合" do
      it "成功を返すこと" do
        result = described_class.new.call({ comment: { content: "テストコメント", task_id: task.id } }, member)
        expect(result.success?).to be true
        expect(result.status).to eq :created
      end

      it "コメントが作成されること" do
        expect {
          described_class.new.call({ comment: { content: "テストコメント", task_id: task.id } }, member)
        }.to change(Comment, :count).by(1)
      end

      it "account_idがcurrent_accountから設定されること" do
        result = described_class.new.call({ comment: { content: "テストコメント", task_id: task.id } }, member)
        expect(result.comment.account_id).to eq member.id
      end

      it "作成されたコメントがaccount情報を含むこと" do
        result = described_class.new.call({ comment: { content: "テストコメント", task_id: task.id } }, member)
        expect(result.comment.account).not_to be_nil
        expect(result.comment.account.name).to eq member.name
      end
    end

    context "adminユーザーの場合" do
      it "成功を返すこと" do
        result = described_class.new.call({ comment: { content: "Adminコメント", task_id: task.id } }, admin)
        expect(result.success?).to be true
        expect(result.comment.account_id).to eq admin.id
      end
    end

    context "デッドロックが発生した場合" do
      let(:mock_repository) { instance_double(Services::Comments::Repository) }
      let(:mock_comment) { instance_double(Comment, id: 1) }

      before do
        allow(mock_repository).to receive(:task_exists?).and_return(true)
        allow(mock_repository).to receive(:build).and_return(mock_comment)
        allow(mock_repository).to receive(:save).and_raise(ActiveRecord::Deadlocked)
      end

      it "service_unavailableを返すこと" do
        result = described_class.new(repository: mock_repository).call(
          { comment: { content: "テスト", task_id: task.id } }, member
        )
        expect(result.success?).to be false
        expect(result.status).to eq :service_unavailable
        expect(result.errors).to include("サーバーが混雑しています。しばらくしてから再試行してください。")
      end
    end

    context "LockWaitTimeoutが発生した場合" do
      let(:mock_repository) { instance_double(Services::Comments::Repository) }
      let(:mock_comment) { instance_double(Comment, id: 1) }

      before do
        allow(mock_repository).to receive(:task_exists?).and_return(true)
        allow(mock_repository).to receive(:build).and_return(mock_comment)
        allow(mock_repository).to receive(:save).and_raise(ActiveRecord::LockWaitTimeout)
      end

      it "service_unavailableを返すこと" do
        result = described_class.new(repository: mock_repository).call(
          { comment: { content: "テスト", task_id: task.id } }, member
        )
        expect(result.success?).to be false
        expect(result.status).to eq :service_unavailable
        expect(result.errors).to include("サーバーが混雑しています。しばらくしてから再試行してください。")
      end
    end

    context "InvalidForeignKeyが発生した場合" do
      let(:mock_repository) { instance_double(Services::Comments::Repository) }
      let(:mock_comment) { instance_double(Comment, id: 1) }

      before do
        allow(mock_repository).to receive(:task_exists?).and_return(true)
        allow(mock_repository).to receive(:build).and_return(mock_comment)
        allow(mock_repository).to receive(:save).and_raise(ActiveRecord::InvalidForeignKey)
      end

      it "conflictを返すこと" do
        result = described_class.new(repository: mock_repository).call(
          { comment: { content: "テスト", task_id: task.id } }, member
        )
        expect(result.success?).to be false
        expect(result.status).to eq :conflict
        expect(result.errors).to include("関連するタスクまたはアカウントが存在しません")
      end
    end

    context "StatementInvalidが発生した場合" do
      let(:mock_repository) { instance_double(Services::Comments::Repository) }
      let(:mock_comment) { instance_double(Comment, id: 1) }

      before do
        allow(mock_repository).to receive(:task_exists?).and_return(true)
        allow(mock_repository).to receive(:build).and_return(mock_comment)
        allow(mock_repository).to receive(:save).and_raise(ActiveRecord::StatementInvalid)
      end

      it "internal_server_errorを返すこと" do
        result = described_class.new(repository: mock_repository).call(
          { comment: { content: "テスト", task_id: task.id } }, member
        )
        expect(result.success?).to be false
        expect(result.status).to eq :internal_server_error
        expect(result.errors).to include("データベースエラーが発生しました")
      end
    end
  end
end
