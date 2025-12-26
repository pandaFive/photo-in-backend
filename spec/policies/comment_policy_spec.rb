# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::CommentPolicy, type: :model do
  let(:admin) { create(:account, role: "admin") }
  let(:member) { create(:account_member) }
  let(:other_member) { create(:account_member, name: "other_member") }
  let(:area) { create(:area) }
  let(:task) { create(:task, area:) }

  describe "#can_view?" do
    context "adminの場合" do
      let(:policy) { described_class.new(admin) }
      let(:member_comment) { create(:comment, account: member, task:) }

      it "他人のコメントを閲覧できること" do
        expect(policy.can_view?(member_comment)).to be true
      end
    end

    context "所有者の場合" do
      let(:policy) { described_class.new(member) }
      let(:own_comment) { create(:comment, account: member, task:) }

      it "自分のコメントを閲覧できること" do
        expect(policy.can_view?(own_comment)).to be true
      end
    end

    context "adminが作成したコメントの場合" do
      let(:policy) { described_class.new(member) }
      let(:admin_comment) { create(:comment, account: admin, task:) }

      it "memberでも閲覧できること" do
        expect(policy.can_view?(admin_comment)).to be true
      end
    end

    context "他のmemberが作成したコメントの場合" do
      let(:policy) { described_class.new(member) }
      let(:other_comment) { create(:comment, account: other_member, task:) }

      it "閲覧できないこと" do
        expect(policy.can_view?(other_comment)).to be false
      end
    end

    context "nilアカウントの場合" do
      let(:policy) { described_class.new(nil) }
      let(:comment) { create(:comment, account: member, task:) }

      it "閲覧できないこと" do
        expect(policy.can_view?(comment)).to be false
      end
    end
  end

  describe "#can_modify?" do
    context "adminの場合" do
      let(:policy) { described_class.new(admin) }
      let(:member_comment) { create(:comment, account: member, task:) }

      it "他人のコメントを編集できること" do
        expect(policy.can_modify?(member_comment)).to be true
      end
    end

    context "所有者の場合" do
      let(:policy) { described_class.new(member) }
      let(:own_comment) { create(:comment, account: member, task:) }

      it "自分のコメントを編集できること" do
        expect(policy.can_modify?(own_comment)).to be true
      end
    end

    context "他のmemberの場合" do
      let(:policy) { described_class.new(member) }
      let(:other_comment) { create(:comment, account: other_member, task:) }

      it "編集できないこと" do
        expect(policy.can_modify?(other_comment)).to be false
      end
    end

    context "adminが作成したコメントの場合" do
      let(:policy) { described_class.new(member) }
      let(:admin_comment) { create(:comment, account: admin, task:) }

      it "memberは編集できないこと" do
        expect(policy.can_modify?(admin_comment)).to be false
      end
    end

    context "nilアカウントの場合" do
      let(:policy) { described_class.new(nil) }
      let(:comment) { create(:comment, account: member, task:) }

      it "編集できないこと" do
        expect(policy.can_modify?(comment)).to be false
      end
    end
  end
end
