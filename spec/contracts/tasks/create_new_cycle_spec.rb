# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Tasks::CreateNewCycle do
  describe ".call" do
    context "有効なパラメータの場合" do
      context "idが文字列の整数の場合" do
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

        it "idが整数に変換されること" do
          result = described_class.call(params)
          expect(result.value[:id]).to eq(123)
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

      context "idが小数の場合" do
        let(:params) { { id: "1.5" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Id must be an integer")
        end
      end
    end
  end

  describe "#normalized_attributes" do
    context "文字列のidの場合" do
      it "idが整数に変換されること" do
        contract = described_class.new(id: "42")
        expect(contract.normalized_attributes).to eq({ id: 42 })
      end
    end

    context "整数のidの場合" do
      it "idがそのまま返されること" do
        contract = described_class.new(id: 100)
        expect(contract.normalized_attributes).to eq({ id: 100 })
      end
    end
  end
end
