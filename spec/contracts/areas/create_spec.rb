# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Areas::Create, type: :contract do
  describe ".call" do
    context "正常系" do
      it "有効なnameで成功すること" do
        result = described_class.call({ name: "東京" })

        expect(result.success?).to be true
        expect(result.value[:name]).to eq("東京")
        expect(result.errors).to be_empty
      end

      it "params[:area][:name]形式で成功すること" do
        result = described_class.call({ area: { name: "大阪" } })

        expect(result.success?).to be true
        expect(result.value[:name]).to eq("大阪")
      end

      it "32文字のnameで成功すること" do
        name = "a" * 32
        result = described_class.call({ name: })

        expect(result.success?).to be true
        expect(result.value[:name]).to eq(name)
      end
    end

    context "異常系" do
      it "nameがnilの場合、失敗すること" do
        result = described_class.call({ name: nil })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "nameが空文字の場合、失敗すること" do
        result = described_class.call({ name: "" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "nameが33文字の場合、失敗すること" do
        name = "a" * 33
        result = described_class.call({ name: })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end
    end
  end
end
