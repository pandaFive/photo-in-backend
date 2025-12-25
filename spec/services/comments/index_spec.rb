# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Comments::Index, type: :model do
  let(:admin) { create(:account, role: "admin") }
  let(:member) { create(:account_member) }
  let(:area) { create(:area) }
  let(:task) { create(:task, area: area) }

  describe "#call" do
    context "認証されていない場合" do
      it "unauthorizedを返すこと" do
        result = described_class.new.call({ task_id: task.id }, nil)
        expect(result.success?).to be false
        expect(result.status).to eq :unauthorized
        expect(result.errors).to include("認証が必要です")
      end
    end

    context "バリデーションエラーの場合" do
      it "task_idがnilの場合、unprocessable_entityを返すこと" do
        result = described_class.new.call({ task_id: nil }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq :unprocessable_entity
      end

      it "task_idが無効な場合、unprocessable_entityを返すこと" do
        result = described_class.new.call({ task_id: "abc" }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq :unprocessable_entity
      end
    end

    context "タスクが存在しない場合" do
      it "not_foundを返すこと" do
        result = described_class.new.call({ task_id: 999999 }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq :not_found
      end
    end

    context "adminユーザーの場合" do
      before do
        @admin_comment = create(:comment, account: admin, task: task, content: "Admin comment")
        @member_comment = create(:comment, account: member, task: task, content: "Member comment")
      end

      it "成功を返すこと" do
        result = described_class.new.call({ task_id: task.id }, admin)
        expect(result.success?).to be true
        expect(result.status).to eq :ok
      end

      it "全てのコメントを取得すること" do
        result = described_class.new.call({ task_id: task.id }, admin)
        expect(result.comments.length).to eq 2
      end
    end

    context "memberユーザーの場合" do
      let(:other_member) { create(:account_member, name: "other_member") }

      before do
        @admin_comment = create(:comment, account: admin, task: task, content: "Admin comment")
        @member_comment = create(:comment, account: member, task: task, content: "Member comment")
        @other_comment = create(:comment, account: other_member, task: task, content: "Other comment")
      end

      it "成功を返すこと" do
        result = described_class.new.call({ task_id: task.id }, member)
        expect(result.success?).to be true
        expect(result.status).to eq :ok
      end

      it "自分とadminのコメントのみを取得すること" do
        result = described_class.new.call({ task_id: task.id }, member)
        expect(result.comments.length).to eq 2
        comment_ids = result.comments.map(&:id)
        expect(comment_ids).to include(@admin_comment.id, @member_comment.id)
        expect(comment_ids).not_to include(@other_comment.id)
      end
    end

    context "DBエラーが発生した場合" do
      let(:mock_repository) { instance_double(Services::Comments::Repository) }

      before do
        allow(mock_repository).to receive(:task_exists?).and_return(true)
        allow(mock_repository).to receive(:get_comments_for_admin).and_raise(ActiveRecord::StatementInvalid)
      end

      it "internal_server_errorを返すこと" do
        result = described_class.new(repository: mock_repository).call({ task_id: task.id }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq :internal_server_error
      end
    end
  end
end
