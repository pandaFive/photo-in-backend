# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presenters::AreaPresenter do
  describe ".render_area" do
    context "有効なエリアの場合" do
      let(:area) { create(:area, name: "東京") }

      it "正しいハッシュ構造を返すこと" do
        result = described_class.render_area(area)

        expect(result).to eq({ id: area.id, name: "東京" })
      end
    end

    context "nilの場合" do
      it "ArgumentErrorをraiseすること" do
        expect {
          described_class.render_area(nil)
        }.to raise_error(ArgumentError, "AreaPresenter.render_area received nil area")
      end
    end
  end

  describe ".render_areas" do
    context "有効なエリア配列の場合" do
      let!(:area1) { create(:area, name: "東京") }
      let!(:area2) { create(:area, name: "大阪") }

      it "ハッシュ配列を返すこと" do
        result = described_class.render_areas([area1, area2])

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result).to include({ id: area1.id, name: "東京" })
        expect(result).to include({ id: area2.id, name: "大阪" })
      end
    end

    context "空配列の場合" do
      it "空配列を返すこと" do
        result = described_class.render_areas([])

        expect(result).to eq([])
      end
    end

    context "nilの場合" do
      it "ArgumentErrorをraiseすること" do
        expect {
          described_class.render_areas(nil)
        }.to raise_error(ArgumentError, "AreaPresenter.render_areas received nil areas")
      end
    end
  end
end
