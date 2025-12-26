# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Tags::IdContract, type: :contract do
  describe ".call" do
    context "正常系" do
      it "正の整数IDで成功すること" do
        result = described_class.call({ id: 1 })

        expect(result.success?).to be true
        expect(result.value[:id]).to eq(1)
        expect(result.errors).to be_empty
      end

      it "文字列形式の正の整数IDで成功すること" do
        result = described_class.call({ id: "123" })

        expect(result.success?).to be true
        expect(result.value[:id]).to eq(123)
        expect(result.errors).to be_empty
      end
    end

    context "異常系" do
      it "idがnilの場合、失敗すること" do
        result = described_class.call({ id: nil })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "idが空文字の場合、失敗すること" do
        result = described_class.call({ id: "" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "idが0の場合、失敗すること" do
        result = described_class.call({ id: 0 })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "idが負数の場合、失敗すること" do
        result = described_class.call({ id: -1 })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "idが数値でない文字列の場合、失敗すること" do
        result = described_class.call({ id: "abc" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "idが小数の場合、失敗すること" do
        result = described_class.call({ id: 1.5 })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end
    end
  end
end
