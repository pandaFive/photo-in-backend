require "rails_helper"

RSpec.describe Account, type: :model do
  describe "validations" do
    it "name, passwordが存在すれば有効であること" do
      account = Account.new(name: "Test User", password: "password123", role: "member", capacity: 3)
      expect(account).to be_valid
    end

    it "nameが存在しない場合は無効であること" do
      account = Account.new(name: nil, password: "password123", role: "member", capacity: 3)
      expect(account).not_to be_valid
    end

    it "nameが32文字を超える場合は無効であること" do
      account = Account.new(name: "a" * 33, password: "password123", role: "member", capacity: 3)
      expect(account).not_to be_valid
    end

    it "passwordが8文字未満の場合は無効であること" do
      account = Account.new(name: "Test User", password: "pass", role: "member", capacity: 3)
      expect(account).not_to be_valid
    end
  end

  describe "associations" do
    it "areasを持っていること" do
      association = Account.reflect_on_association(:areas)
      expect(association.macro).to eq(:has_many)
    end

    it "tagsを持っていること" do
      association = Account.reflect_on_association(:tags)
      expect(association.macro).to eq(:has_many)
    end

    it "commentsを持っていること" do
      association = Account.reflect_on_association(:comments)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe "#add_area" do
    it "アカウントにエリアを追加できること" do
      account = create(:account_member)
      area = create(:area)

      expect { account.add_area(area) }.to change { account.areas.count }.by(1)
      expect(account.areas).to include(area)
    end
  end

  describe "#add_areas" do
    it "アカウントに複数のエリアを追加できること" do
      account = create(:account_member)
      area1 = create(:area, name: "Area 1")
      area2 = create(:area, name: "Area 2")

      expect { account.add_areas([area1.id, area2.id]) }.to change { account.areas.count }.by(2)
      expect(account.areas).to include(area1, area2)
    end
  end

  describe "#remove_area" do
    it "アカウントからエリアを削除できること" do
      account = create(:account_member)
      area = create(:area)
      account.add_area(area)

      expect { account.remove_area(area) }.to change { account.areas.count }.by(-1)
      expect(account.areas).not_to include(area)
    end
  end

  describe "#add_tag" do
    it "アカウントにタグを追加できること" do
      account = create(:account_member)
      tag = Tag.create(name: "Test Tag")

      expect { account.add_tag(tag) }.to change { account.tags.count }.by(1)
      expect(account.tags).to include(tag)
    end
  end

  describe "#remove_tag" do
    it "アカウントからタグを削除できること" do
      account = create(:account_member)
      tag = Tag.create(name: "Test Tag")
      account.add_tag(tag)

      expect { account.remove_tag(tag) }.to change { account.tags.count }.by(-1)
      expect(account.tags).not_to include(tag)
    end
  end
end
