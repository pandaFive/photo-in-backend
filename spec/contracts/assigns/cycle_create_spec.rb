# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Assigns::CycleCreate do
  describe ".call" do
    context "有効なパラメータの場合" do
      context "assign_cycleネストありの場合" do
        let(:params) { { assign_cycle: { task_id: "1" } } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "valueにnormalized_attributesを返すこと" do
          result = described_class.call(params)
          expect(result.value).to eq({ task_id: 1 })
        end

        it "errorsが空であること" do
          result = described_class.call(params)
          expect(result.errors).to be_empty
        end
      end

      context "assign_cycleネストなしの場合" do
        let(:params) { { task_id: "123" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "task_idが整数に変換されること" do
          result = described_class.call(params)
          expect(result.value[:task_id]).to eq(123)
        end
      end

      context "task_idが整数の場合" do
        let(:params) { { assign_cycle: { task_id: 456 } } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "task_idがそのまま整数として返されること" do
          result = described_class.call(params)
          expect(result.value[:task_id]).to eq(456)
        end
      end
    end

    context "無効なパラメータの場合" do
      context "task_idが空文字列の場合" do
        let(:params) { { assign_cycle: { task_id: "" } } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("タスクIDは必須です")
        end
      end

      context "task_idがnilの場合" do
        let(:params) { { assign_cycle: { task_id: nil } } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("タスクIDは必須です")
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
          expect(result.errors.first).to include("タスクIDは必須です")
        end
      end

      context "task_idが非数値の場合" do
        let(:params) { { assign_cycle: { task_id: "abc" } } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("タスクIDは正の整数である必要があります")
        end
      end

      context "task_idが0の場合" do
        let(:params) { { assign_cycle: { task_id: "0" } } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("タスクIDは正の整数である必要があります")
        end
      end

      context "task_idが負数の場合" do
        let(:params) { { assign_cycle: { task_id: "-1" } } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("タスクIDは正の整数である必要があります")
        end
      end

      context "task_idが小数の場合" do
        let(:params) { { assign_cycle: { task_id: "1.5" } } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors.first).to include("タスクIDは正の整数である必要があります")
        end
      end
    end
  end

  describe "#normalized_attributes" do
    context "文字列のtask_idの場合" do
      it "task_idが整数に変換されること" do
        contract = described_class.new(task_id: "42")
        expect(contract.normalized_attributes).to eq({ task_id: 42 })
      end
    end

    context "整数のtask_idの場合" do
      it "task_idがそのまま返されること" do
        contract = described_class.new(task_id: 100)
        expect(contract.normalized_attributes).to eq({ task_id: 100 })
      end
    end
  end
end
