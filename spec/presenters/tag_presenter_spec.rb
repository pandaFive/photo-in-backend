# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presenters::TagPresenter, type: :model do
  describe ".render_tag" do
    context "有効なタグの場合" do
      let(:tag) { create(:tag, name: "緊急") }

      it "正しいハッシュ構造を返すこと" do
        result = described_class.render_tag(tag)

        expect(result).to eq({ id: tag.id, name: "緊急" })
      end
    end

    context "nilの場合" do
      it "nilを返すこと" do
        result = described_class.render_tag(nil)

        expect(result).to be_nil
      end

      it "警告ログを出力すること" do
        expect(Rails.logger).to receive(:warn).with(/received nil tag/)
        described_class.render_tag(nil)
      end
    end
  end

  describe ".render_tags" do
    context "有効なタグ配列の場合" do
      let!(:tag1) { create(:tag, name: "緊急") }
      let!(:tag2) { create(:tag, name: "重要") }

      it "ハッシュ配列を返すこと" do
        result = described_class.render_tags([tag1, tag2])

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result).to include({ id: tag1.id, name: "緊急" })
        expect(result).to include({ id: tag2.id, name: "重要" })
      end
    end

    context "空配列の場合" do
      it "空配列を返すこと" do
        result = described_class.render_tags([])

        expect(result).to eq([])
      end
    end

    context "nilの場合" do
      it "空配列を返すこと" do
        result = described_class.render_tags(nil)

        expect(result).to eq([])
      end

      it "警告ログを出力すること" do
        expect(Rails.logger).to receive(:warn).with(/received nil tags/)
        described_class.render_tags(nil)
      end
    end
  end
end
