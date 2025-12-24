# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Tasks::Update do
  describe ".call" do
    context "有効なパラメータの場合" do
      context "idとtask_titleの両方を指定" do
        let(:params) { { id: "1", task_title: "更新後タイトル" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "valueにnormalized_attributesを返すこと" do
          result = described_class.call(params)
          expect(result.value).to eq({ id: 1, task_title: "更新後タイトル" })
        end

        it "errorsが空であること" do
          result = described_class.call(params)
          expect(result.errors).to be_empty
        end
      end

      context "idのみ指定（task_titleなし）" do
        let(:params) { { id: "1" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "valueにidのみ含まれること" do
          result = described_class.call(params)
          expect(result.value).to eq({ id: 1 })
        end
      end

      context "idが整数の場合" do
        let(:params) { { id: 123, task_title: "タイトル" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "idがそのまま返されること" do
          result = described_class.call(params)
          expect(result.value[:id]).to eq(123)
        end
      end

      context "task_titleが空文字の場合" do
        let(:params) { { id: "1", task_title: "" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "valueにtask_titleが含まれないこと" do
          result = described_class.call(params)
          expect(result.value).to eq({ id: 1 })
          expect(result.value).not_to have_key(:task_title)
        end
      end

      context "task_titleがnilの場合" do
        let(:params) { { id: "1", task_title: nil } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "valueにtask_titleが含まれないこと" do
          result = described_class.call(params)
          expect(result.value).to eq({ id: 1 })
        end
      end
    end

    context "無効なパラメータの場合" do
      context "idが空文字列の場合" do
        let(:params) { { id: "", task_title: "タイトル" } }

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
        let(:params) { { id: nil, task_title: "タイトル" } }

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

      context "task_titleが256文字を超える場合" do
        let(:params) { { id: "1", task_title: "あ" * 257 } }

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
        let(:params) { { id: "1", task_title: "あ" * 256 } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end

        it "task_titleがvalueに含まれること" do
          result = described_class.call(params)
          expect(result.value[:task_title]).to eq("あ" * 256)
        end
      end

      context "task_titleが1文字の場合" do
        let(:params) { { id: "1", task_title: "あ" } }

        it "success?がtrueを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be true
        end
      end
    end

    context "セキュリティ：非スカラー値の拒否" do
      context "task_titleが配列の場合" do
        let(:params) { { id: "1", task_title: ["a" * 100, "b" * 100, "c" * 100] } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "errorsにtask_titleのエラーが含まれること" do
          result = described_class.call(params)
          expect(result.errors.first).to include("文字列である必要があります")
        end
      end

      context "task_titleがハッシュの場合" do
        let(:params) { { id: "1", task_title: { key: "value" } } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end

        it "errorsにtask_titleのエラーが含まれること" do
          result = described_class.call(params)
          expect(result.errors.first).to include("文字列である必要があります")
        end
      end

      context "task_titleが数値の場合" do
        let(:params) { { id: "1", task_title: 12345 } }

        it "success?がfalseを返すこと" do
          result = described_class.call(params)
          expect(result.success?).to be false
        end
      end
    end
  end

  describe "#normalized_attributes" do
    context "task_titleが指定されている場合" do
      it "idとtask_titleを含むこと" do
        contract = described_class.new(id: "1", task_title: "タイトル")
        expect(contract.normalized_attributes).to eq({ id: 1, task_title: "タイトル" })
      end
    end

    context "task_titleがnilの場合" do
      it "idのみ含むこと" do
        contract = described_class.new(id: "1", task_title: nil)
        expect(contract.normalized_attributes).to eq({ id: 1 })
      end
    end

    context "task_titleが空文字の場合" do
      it "idのみ含むこと" do
        contract = described_class.new(id: "1", task_title: "")
        expect(contract.normalized_attributes).to eq({ id: 1 })
      end
    end
  end
end
