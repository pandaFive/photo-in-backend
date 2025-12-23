require "rails_helper"

RSpec.describe Contracts::Tasks::Create do
  describe ".call" do
    context "有効なパラメータの場合" do
      context "task_titleとarea_idの両方を指定" do
        let(:params) { { task_title: "テスト撮影タスク", area_id: 1 } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "valueにnormalized_attributesを返すこと" do
          result = described_class.call(params)
          expect(result.value).to eq({ task_title: "テスト撮影タスク", area_id: 1 })
        end

        it "errorsが空であること" do
          result = described_class.call(params)
          expect(result.errors).to be_empty
        end
      end

      context "task_titleのみ指定（area_idは任意）" do
        let(:params) { { task_title: "テスト撮影タスク" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "area_idがnilのvalueを返すこと" do
          result = described_class.call(params)
          expect(result.value).to eq({ task_title: "テスト撮影タスク", area_id: nil })
        end
      end

      context "area_idが文字列の場合" do
        let(:params) { { task_title: "テスト撮影タスク", area_id: "2" } }

        it "area_idを整数に変換すること" do
          result = described_class.call(params)
          expect(result.value[:area_id]).to eq(2)
        end
      end
    end

    context "無効なパラメータの場合" do
      context "task_titleが空の場合" do
        let(:params) { { task_title: "", area_id: 1 } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Task title can't be blank")
        end
      end

      context "task_titleがnilの場合" do
        let(:params) { { task_title: nil, area_id: 1 } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Task title can't be blank")
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
          expect(result.errors).to include("Task title can't be blank")
        end
      end

      context "task_titleが256文字を超える場合" do
        let(:params) { { task_title: "あ" * 257 } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Task title is too long (maximum is 256 characters)")
        end
      end
    end

    context "境界値テスト" do
      context "task_titleが256文字の場合" do
        let(:params) { { task_title: "あ" * 256 } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end
      end

      context "task_titleが1文字の場合" do
        let(:params) { { task_title: "あ" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end
      end
    end
  end
end
