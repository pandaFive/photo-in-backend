# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Comments::Destroy, type: :model do
  let(:admin) { create(:account, role: "admin") }
  let(:member) { create(:account_member) }
  let(:other_member) { create(:account_member, name: "other_member") }
  let(:area) { create(:area) }
  let(:task) { create(:task, area:) }

  describe "#call" do
    context "認証されていない場合" do
      let(:comment) { create(:comment, account: member, task:) }

      it "unauthorizedを返すこと" do
        result = described_class.new.call({ id: comment.id }, nil)
        expect(result.success?).to be false
        expect(result.status).to eq :unauthorized
        expect(result.errors).to include("認証が必要です")
      end
    end

    context "バリデーションエラーの場合" do
      it "idがnilの場合、unprocessable_entityを返すこと" do
        result = described_class.new.call({ id: nil }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq :unprocessable_entity
      end

      it "idが無効な場合、unprocessable_entityを返すこと" do
        result = described_class.new.call({ id: "abc" }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq :unprocessable_entity
      end
    end

    context "コメントが存在しない場合" do
      it "not_foundを返すこと" do
        result = described_class.new.call({ id: 999999 }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq :not_found
      end
    end

    context "所有者の場合" do
      let!(:own_comment) { create(:comment, account: member, task:) }

      it "削除できること" do
        result = described_class.new.call({ id: own_comment.id }, member)
        expect(result.success?).to be true
        expect(result.status).to eq :ok
        expect(result.message).to eq "deleted"
      end

      it "コメントが削除されること" do
        expect {
          described_class.new.call({ id: own_comment.id }, member)
        }.to change(Comment, :count).by(-1)
      end
    end

    context "adminの場合" do
      let!(:member_comment) { create(:comment, account: member, task:) }

      it "他人のコメントを削除できること" do
        result = described_class.new.call({ id: member_comment.id }, admin)
        expect(result.success?).to be true
        expect(result.message).to eq "deleted"
      end
    end

    context "他のmemberの場合" do
      let!(:other_comment) { create(:comment, account: other_member, task:) }

      it "削除できないこと" do
        result = described_class.new.call({ id: other_comment.id }, member)
        expect(result.success?).to be false
        expect(result.status).to eq :forbidden
        expect(result.errors).to include("このコメントを削除する権限がありません")
      end
    end

    context "デッドロックが発生した場合" do
      let(:comment) { create(:comment, account: member, task:) }
      let(:mock_repository) { instance_double(Services::Comments::Repository) }

      before do
        allow(mock_repository).to receive(:find_by_id_with_lock).and_raise(ActiveRecord::Deadlocked)
      end

      it "service_unavailableを返すこと" do
        result = described_class.new(repository: mock_repository).call({ id: comment.id }, member)
        expect(result.success?).to be false
        expect(result.status).to eq :service_unavailable
      end
    end

    context "LockWaitTimeoutが発生した場合" do
      let(:comment) { create(:comment, account: member, task:) }
      let(:mock_repository) { instance_double(Services::Comments::Repository) }

      before do
        allow(mock_repository).to receive(:find_by_id_with_lock).and_raise(ActiveRecord::LockWaitTimeout)
      end

      it "service_unavailableを返すこと" do
        result = described_class.new(repository: mock_repository).call({ id: comment.id }, member)
        expect(result.success?).to be false
        expect(result.status).to eq :service_unavailable
        expect(result.errors).to include("サーバーが混雑しています。しばらくしてから再試行してください。")
      end
    end

    context "StatementInvalidが発生した場合" do
      let(:comment) { create(:comment, account: member, task:) }
      let(:mock_repository) { instance_double(Services::Comments::Repository) }

      before do
        allow(mock_repository).to receive(:find_by_id_with_lock).and_return(comment)
        allow(mock_repository).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid)
      end

      it "internal_server_errorを返すこと" do
        result = described_class.new(repository: mock_repository).call({ id: comment.id }, member)
        expect(result.success?).to be false
        expect(result.status).to eq :internal_server_error
        expect(result.errors).to include("データベースエラーが発生しました")
      end
    end
  end
end
