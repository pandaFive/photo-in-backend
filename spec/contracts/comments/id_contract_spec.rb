# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Comments::IdContract, type: :model do
  describe ".call" do
    context "有効なパラメータの場合" do
      it "成功を返すこと" do
        result = described_class.call(id: 1)
        expect(result.success?).to be true
      end

      it "正規化されたidを返すこと" do
        result = described_class.call(id: "5")
        expect(result.value[:id]).to eq 5
      end
    end

    context "idがnilの場合" do
      it "失敗を返すこと" do
        result = described_class.call(id: nil)
        expect(result.success?).to be false
        expect(result.errors).to include("Id can't be blank")
      end
    end

    context "idが空文字の場合" do
      it "失敗を返すこと" do
        result = described_class.call(id: "")
        expect(result.success?).to be false
      end
    end

    context "idが0の場合" do
      it "失敗を返すこと" do
        result = described_class.call(id: 0)
        expect(result.success?).to be false
        expect(result.errors).to include("Id must be greater than 0")
      end
    end

    context "idが負数の場合" do
      it "失敗を返すこと" do
        result = described_class.call(id: -1)
        expect(result.success?).to be false
      end
    end

    context "idが文字列の場合" do
      it "失敗を返すこと" do
        result = described_class.call(id: "abc")
        expect(result.success?).to be false
        expect(result.errors).to include("Id is not a number")
      end
    end
  end
end
