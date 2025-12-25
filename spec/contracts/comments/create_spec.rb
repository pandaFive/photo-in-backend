# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Comments::Create, type: :model do
  describe ".call" do
    context "有効なパラメータの場合" do
      it "成功を返すこと" do
        result = described_class.call(comment: { content: "テストコメント", task_id: 1 })
        expect(result.success?).to be true
      end

      it "正規化された値を返すこと" do
        result = described_class.call(comment: { content: "テストコメント", task_id: "5" })
        expect(result.value[:content]).to eq "テストコメント"
        expect(result.value[:task_id]).to eq 5
      end
    end

    context "contentがnilの場合" do
      it "失敗を返すこと" do
        result = described_class.call(comment: { content: nil, task_id: 1 })
        expect(result.success?).to be false
        expect(result.errors).to include("Content can't be blank")
      end
    end

    context "contentが空文字の場合" do
      it "失敗を返すこと" do
        result = described_class.call(comment: { content: "", task_id: 1 })
        expect(result.success?).to be false
      end
    end

    context "contentが1000文字を超える場合" do
      it "失敗を返すこと" do
        result = described_class.call(comment: { content: "a" * 1001, task_id: 1 })
        expect(result.success?).to be false
        expect(result.errors).to include("Content is too long (maximum is 1000 characters)")
      end
    end

    context "contentがちょうど1000文字の場合" do
      it "成功を返すこと" do
        result = described_class.call(comment: { content: "a" * 1000, task_id: 1 })
        expect(result.success?).to be true
      end
    end

    context "task_idがnilの場合" do
      it "失敗を返すこと" do
        result = described_class.call(comment: { content: "テスト", task_id: nil })
        expect(result.success?).to be false
        expect(result.errors).to include("Task can't be blank")
      end
    end

    context "task_idが0の場合" do
      it "失敗を返すこと" do
        result = described_class.call(comment: { content: "テスト", task_id: 0 })
        expect(result.success?).to be false
        expect(result.errors).to include("Task must be greater than 0")
      end
    end

    context "commentパラメータがない場合" do
      it "失敗を返すこと" do
        result = described_class.call({})
        expect(result.success?).to be false
      end
    end
  end
end
