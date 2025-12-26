# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presenters::CommentPresenter, type: :model do
  let(:admin) { create(:account, role: "admin") }
  let(:member) { create(:account_member) }
  let(:area) { create(:area) }
  let(:task) { create(:task, area:) }

  describe ".render_comment" do
    context "有効なコメントの場合" do
      let(:comment) { create(:comment, account: member, task:, content: "テストコメント") }

      it "正しい形式を返すこと" do
        result = described_class.render_comment(comment)
        expect(result[:id]).to eq comment.id
        expect(result[:content]).to eq "テストコメント"
        expect(result[:task_id]).to eq task.id
        expect(result[:account_id]).to eq member.id
        expect(result[:account_name]).to eq member.name
        expect(result[:account_role]).to eq "member"
        expect(result[:updated_at]).to be_present
      end

      it "updated_atがISO8601形式であること" do
        result = described_class.render_comment(comment)
        expect { Time.iso8601(result[:updated_at]) }.not_to raise_error
      end
    end

    context "nilの場合" do
      it "nilを返すこと" do
        result = described_class.render_comment(nil)
        expect(result).to be_nil
      end
    end
  end

  describe ".render_comments" do
    context "有効なコメント配列の場合" do
      let(:comment1) { create(:comment, account: admin, task:, content: "Admin comment") }
      let(:comment2) { create(:comment, account: member, task:, content: "Member comment") }

      it "全てのコメントを変換すること" do
        result = described_class.render_comments([comment1, comment2])
        expect(result.length).to eq 2
        expect(result[0][:content]).to eq "Admin comment"
        expect(result[1][:content]).to eq "Member comment"
      end
    end

    context "空配列の場合" do
      it "空配列を返すこと" do
        result = described_class.render_comments([])
        expect(result).to eq []
      end
    end

    context "nilの場合" do
      it "空配列を返すこと" do
        result = described_class.render_comments(nil)
        expect(result).to eq []
      end
    end
  end
end
