# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Comments::Create, type: :model do
  let(:admin) { create(:account, role: "admin") }
  let(:member) { create(:account_member) }
  let(:area) { create(:area) }
  let(:task) { create(:task, area: area) }

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
  end
end
