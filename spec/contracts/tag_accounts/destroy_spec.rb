# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::TagAccounts::Destroy do
  describe ".call" do
    context "有効なパラメータの場合" do
      let(:params) { { account_id: "1", tag_id: "2" } }

      it "success?がtrueを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be true
      end

      it "valueにnormalized_attributesを返すこと" do
        result = described_class.call(params)
        expect(result.value).to eq({ account_id: 1, tag_id: 2 })
      end

      it "errorsが空であること" do
        result = described_class.call(params)
        expect(result.errors).to be_empty
      end
    end

    context "無効なパラメータの場合" do
      context "account_idが空の場合" do
        let(:params) { { account_id: "", tag_id: "1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("アカウントIDは必須です")
        end
      end

      context "tag_idが空の場合" do
        let(:params) { { account_id: "1", tag_id: "" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("タグIDは必須です")
        end
      end

      context "account_idが非数値の場合" do
        let(:params) { { account_id: "abc", tag_id: "1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end

      context "tag_idが非数値の場合" do
        let(:params) { { account_id: "1", tag_id: "xyz" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end
    end
  end
end
