# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Accounts::Create do
  describe ".call" do
    context "有効なパラメータの場合" do
      let(:params) { { name: "Test", password: "password123", role: "member", area: [1, 2] } }

      it "success?がtrueを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be true
      end

      it "normalized_attributesを返すこと" do
        result = described_class.call(params)
        expect(result.value[:area_ids]).to eq([1, 2])
      end
    end

    context "無効なパラメータの場合" do
      let(:params) { { name: "", password: "short", role: "invalid" } }

      it "success?がfalseを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be false
      end

      it "エラーメッセージを返すこと" do
        result = described_class.call(params)
        expect(result.errors).to include("Name can't be blank")
      end
    end
  end
end
