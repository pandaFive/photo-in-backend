# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Tasks::RemoveTag do
  describe ".call" do
    context "有効なパラメータの場合" do
      context "task_idとtag_idが文字列の整数の場合" do
        let(:params) { { task_id: "1", tag_id: "2" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "valueにnormalized_attributesを返すこと" do
          result = described_class.call(params)
          expect(result.value).to eq({ task_id: 1, tag_id: 2 })
        end

        it "errorsが空であること" do
          result = described_class.call(params)
          expect(result.errors).to be_empty
        end
      end

      context "task_idとtag_idが整数の場合" do
        let(:params) { { task_id: 123, tag_id: 456 } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "整数に変換されること" do
          result = described_class.call(params)
          expect(result.value[:task_id]).to eq(123)
          expect(result.value[:tag_id]).to eq(456)
        end
      end

      context "idパラメータが使用される場合（ルート互換性）" do
        let(:params) { { id: "10", tag_id: "20" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "idがtask_idとして扱われること" do
          result = described_class.call(params)
          expect(result.value[:task_id]).to eq(10)
        end
      end
    end

    context "無効なパラメータの場合" do
      context "task_idが空の場合" do
        let(:params) { { task_id: "", tag_id: "1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Task can't be blank")
        end
      end

      context "task_idがnilの場合" do
        let(:params) { { task_id: nil, tag_id: "1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end

      context "task_idが非数値の場合" do
        let(:params) { { task_id: "abc", tag_id: "1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Task is not a number")
        end
      end

      context "task_idが0の場合" do
        let(:params) { { task_id: "0", tag_id: "1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Task must be greater than 0")
        end
      end

      context "task_idが負数の場合" do
        let(:params) { { task_id: "-1", tag_id: "1" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end

      context "tag_idが空の場合" do
        let(:params) { { task_id: "1", tag_id: "" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Tag can't be blank")
        end
      end

      context "tag_idがnilの場合" do
        let(:params) { { task_id: "1", tag_id: nil } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end

      context "tag_idが非数値の場合" do
        let(:params) { { task_id: "1", tag_id: "xyz" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "エラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Tag is not a number")
        end
      end

      context "tag_idが0の場合" do
        let(:params) { { task_id: "1", tag_id: "0" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end

      context "tag_idが負数の場合" do
        let(:params) { { task_id: "1", tag_id: "-5" } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end

      context "両方のパラメータが空の場合" do
        let(:params) { {} }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "複数のエラーメッセージを返すこと" do
          result = described_class.call(params)
          expect(result.errors).to include("Task can't be blank")
          expect(result.errors).to include("Tag can't be blank")
        end
      end
    end
  end

  describe "#normalized_attributes" do
    context "文字列の場合" do
      it "整数に変換されること" do
        contract = described_class.new(task_id: "42", tag_id: "24")
        expect(contract.normalized_attributes).to eq({ task_id: 42, tag_id: 24 })
      end
    end

    context "整数の場合" do
      it "そのまま返されること" do
        contract = described_class.new(task_id: 100, tag_id: 200)
        expect(contract.normalized_attributes).to eq({ task_id: 100, tag_id: 200 })
      end
    end
  end
end
