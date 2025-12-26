# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::AccountAreas::Destroy do
  describe ".call" do
    context "有効なパラメータの場合" do
      let(:params) { { account_id: "1", area_id: "2" } }

      it "success?がtrueを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be true
      end

      it "valueにnormalized_attributesを返すこと" do
        result = described_class.call(params)
        expect(result.value).to eq({ account_id: 1, area_id: 2 })
      end

      it "errorsが空であること" do
        result = described_class.call(params)
        expect(result.errors).to be_empty
      end
    end

    context "無効なパラメータの場合" do
      context "account_idが空の場合" do
        let(:params) { { account_id: "", area_id: "1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("アカウントIDは必須です")
        end
      end

      context "area_idが空の場合" do
        let(:params) { { account_id: "1", area_id: "" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("エリアIDは必須です")
        end
      end

      context "account_idが非数値の場合" do
        let(:params) { { account_id: "abc", area_id: "1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end

      context "area_idが非数値の場合" do
        let(:params) { { account_id: "1", area_id: "xyz" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end
    end
  end
end
