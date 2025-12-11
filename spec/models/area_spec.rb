require "rails_helper"

RSpec.describe Area, type: :model do
  describe "validations" do
    it "nameが存在すれば有効であること" do
      area = Area.new(name: "Test Area")
      expect(area).to be_valid
    end

    it "nameが存在しない場合は無効であること" do
      area = Area.new(name: nil)
      expect(area).not_to be_valid
    end

    it "nameが32文字を超える場合は無効であること" do
      area = Area.new(name: "a" * 33)
      expect(area).not_to be_valid
    end
  end

  describe "associations" do
    it "accountsを持っていること" do
      association = Area.reflect_on_association(:accounts)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe ".get_all_area" do
    it "全てのエリアを取得できること" do
      area1 = create(:area, name: "Area 1")
      area2 = create(:area, name: "Area 2")

      areas = Area.get_all_area

      expect(areas.length).to eq(2)
      expect(areas.map(&:id)).to include(area1.id, area2.id)
      expect(areas.map(&:name)).to include(area1.name, area2.name)
    end
  end

  describe ".get_area_id" do
    it "タイトルに含まれるエリア名からエリアIDを取得できること" do
      area = create(:area, name: "テストエリア")

      area_id = Area.get_area_id("テストエリアのタスク")

      expect(area_id).to eq(area.id)
    end

    it "エリア名が含まれていない場合はnilを返すこと" do
      area_id = Area.get_area_id("存在しないエリアのタスク")

      expect(area_id).to be_nil
    end

    it "複数のエリア名が一致する場合は最初のエリアIDを返すこと" do
      area1 = create(:area, name: "エリアA")
      area2 = create(:area, name: "エリアB")

      area_id = Area.get_area_id("エリアAとエリアBのタスク")

      expect([area1.id, area2.id]).to include(area_id)
    end
  end
end
