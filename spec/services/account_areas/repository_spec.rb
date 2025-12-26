# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::AccountAreas::Repository, type: :service do
  let(:repository) { described_class.new }
  let!(:account) { create(:account_member) }
  let!(:area) { create(:area) }

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

  describe "#find_area" do
    context "存在するIDの場合" do
      it "エリアを返すこと" do
        result = repository.find_area(area.id)
        expect(result).to eq(area)
      end
    end

    context "存在しないIDの場合" do
      it "nilを返すこと" do
        result = repository.find_area(999999)
        expect(result).to be_nil
      end
    end
  end

  describe "#area_exists?" do
    context "エリアが紐付いている場合" do
      before { account.areas << area }

      it "trueを返すこと" do
        result = repository.area_exists?(account, area)
        expect(result).to be true
      end
    end

    context "エリアが紐付いていない場合" do
      it "falseを返すこと" do
        result = repository.area_exists?(account, area)
        expect(result).to be false
      end
    end
  end

  describe "#add_area" do
    context "エリアが未追加の場合" do
      it "trueを返すこと" do
        result = repository.add_area(account, area)
        expect(result).to be true
      end

      it "エリアが追加されること" do
        repository.add_area(account, area)
        expect(account.areas).to include(area)
      end

      it "AccountAreaレコードが作成されること" do
        expect {
          repository.add_area(account, area)
        }.to change(AccountArea, :count).by(1)
      end
    end
  end

  describe "#remove_area" do
    before { account.areas << area }

    it "trueを返すこと" do
      result = repository.remove_area(account, area)
      expect(result).to be true
    end

    it "エリアが削除されること" do
      repository.remove_area(account, area)
      expect(account.areas).not_to include(area)
    end

    it "AccountAreaレコードが削除されること" do
      expect {
        repository.remove_area(account, area)
      }.to change(AccountArea, :count).by(-1)
    end
  end

  describe "#get_areas" do
    context "エリアがある場合" do
      let!(:area2) { create(:area, name: "東京") }

      before do
        account.areas << area
        account.areas << area2
      end

      it "エリア一覧を返すこと" do
        result = repository.get_areas(account)
        expect(result.length).to eq(2)
      end
    end

    context "エリアがない場合" do
      it "空配列を返すこと" do
        result = repository.get_areas(account)
        expect(result).to be_empty
      end
    end
  end
end
