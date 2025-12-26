# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::TagAccounts::Repository, type: :service do
  let(:repository) { described_class.new }
  let!(:account) { create(:account_member) }
  let!(:tag) { create(:tag) }

  describe "#find_account" do
    context "存在するIDの場合" do
      it "アカウントを返すこと" do
        result = repository.find_account(account.id)
        expect(result).to eq(account)
      end
    end

    context "存在しないIDの場合" do
      it "nilを返すこと" do
        result = repository.find_account(999999)
        expect(result).to be_nil
      end
    end
  end

  describe "#find_tag" do
    context "存在するIDの場合" do
      it "タグを返すこと" do
        result = repository.find_tag(tag.id)
        expect(result).to eq(tag)
      end
    end

    context "存在しないIDの場合" do
      it "nilを返すこと" do
        result = repository.find_tag(999999)
        expect(result).to be_nil
      end
    end
  end

  describe "#tag_exists?" do
    context "タグが紐付いている場合" do
      before { account.tags << tag }

      it "trueを返すこと" do
        result = repository.tag_exists?(account, tag)
        expect(result).to be true
      end
    end

    context "タグが紐付いていない場合" do
      it "falseを返すこと" do
        result = repository.tag_exists?(account, tag)
        expect(result).to be false
      end
    end
  end

  describe "#add_tag" do
    context "タグが未追加の場合" do
      it "trueを返すこと" do
        result = repository.add_tag(account, tag)
        expect(result).to be true
      end

      it "タグが追加されること" do
        repository.add_tag(account, tag)
        expect(account.tags).to include(tag)
      end

      it "TagAccountレコードが作成されること" do
        expect {
          repository.add_tag(account, tag)
        }.to change(TagAccount, :count).by(1)
      end
    end

    context "RecordNotUniqueが発生した場合" do
      before do
        allow(account.tags).to receive(:<<).and_raise(ActiveRecord::RecordNotUnique.new("Duplicate entry"))
      end

      it "falseを返すこと" do
        result = repository.add_tag(account, tag)
        expect(result).to be false
      end

      it "例外を発生させないこと" do
        expect { repository.add_tag(account, tag) }.not_to raise_error
      end
    end
  end

  describe "#remove_tag" do
    context "タグが紐付いている場合" do
      before { account.tags << tag }

      it "trueを返すこと" do
        result = repository.remove_tag(account, tag)
        expect(result).to be true
      end

      it "タグが削除されること" do
        repository.remove_tag(account, tag)
        expect(account.tags).not_to include(tag)
      end

      it "TagAccountレコードが削除されること" do
        expect {
          repository.remove_tag(account, tag)
        }.to change(TagAccount, :count).by(-1)
      end
    end

    context "RecordNotDestroyedが発生した場合" do
      before do
        account.tags << tag
        allow(account.tags).to receive(:destroy).and_raise(ActiveRecord::RecordNotDestroyed.new("Cannot destroy"))
      end

      it "falseを返すこと" do
        result = repository.remove_tag(account, tag)
        expect(result).to be false
      end

      it "例外を発生させないこと" do
        expect { repository.remove_tag(account, tag) }.not_to raise_error
      end
    end

    context "タグが紐付いていない場合" do
      it "falseを返すこと" do
        result = repository.remove_tag(account, tag)
        expect(result).to be false
      end
    end
  end

  describe "#get_tags" do
    context "タグがある場合" do
      let!(:tag2) { create(:tag, name: "重要") }

      before do
        account.tags << tag
        account.tags << tag2
      end

      it "タグ一覧を返すこと" do
        result = repository.get_tags(account)
        expect(result.length).to eq(2)
      end
    end

    context "タグがない場合" do
      it "空配列を返すこと" do
        result = repository.get_tags(account)
        expect(result).to be_empty
      end
    end
  end
end
