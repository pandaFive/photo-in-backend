# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Tasks::Show do
  describe ".call" do
    context "有効なパラメータの場合" do
      context "idが数値文字列の場合" do
        let(:params) { { id: "1" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "valueにnormalized_attributesを返すこと" do
          result = described_class.call(params)
          expect(result.value).to eq({ id: 1 })
        end

        it "errorsが空であること" do
          result = described_class.call(params)
          expect(result.errors).to be_empty
        end
      end

      context "idが整数の場合" do
        let(:params) { { id: 123 } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "valueにnormalized_attributesを返すこと" do
          result = described_class.call(params)
          expect(result.value).to eq({ id: 123 })
        end
      end
    end

    context "無効なパラメータの場合" do
      context "idが空文字列の場合" do
        let(:params) { { id: "" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Id can't be blank")
        end
      end

      context "idがnilの場合" do
        let(:params) { { id: nil } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Id can't be blank")
        end
      end

      context "パラメータが空の場合" do
        let(:params) { {} }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Id can't be blank")
        end
      end

      context "idが非数値の場合" do
        let(:params) { { id: "abc" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Id is not a number")
        end
      end

      context "idが0の場合" do
        let(:params) { { id: "0" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Id must be greater than 0")
        end
      end

      context "idが負数の場合" do
        let(:params) { { id: "-1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Id must be greater than 0")
        end
      end
    end
  end
end
