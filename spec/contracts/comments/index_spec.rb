# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Comments::Index, type: :model do
  describe ".call" do
    context "有効なパラメータの場合" do
      it "成功を返すこと" do
        result = described_class.call(task_id: 1)
        expect(result.success?).to be true
      end

      it "正規化されたtask_idを返すこと" do
        result = described_class.call(task_id: "5")
        expect(result.value[:task_id]).to eq 5
      end
    end

    context "task_idがnilの場合" do
      it "失敗を返すこと" do
        result = described_class.call(task_id: nil)
        expect(result.success?).to be false
        expect(result.errors).to include("Task can't be blank")
      end
    end

    context "task_idが空文字の場合" do
      it "失敗を返すこと" do
        result = described_class.call(task_id: "")
        expect(result.success?).to be false
      end
    end

    context "task_idが0の場合" do
      it "失敗を返すこと" do
        result = described_class.call(task_id: 0)
        expect(result.success?).to be false
        expect(result.errors).to include("Task must be greater than 0")
      end
    end

    context "task_idが負数の場合" do
      it "失敗を返すこと" do
        result = described_class.call(task_id: -1)
        expect(result.success?).to be false
      end
    end

    context "task_idが文字列の場合" do
      it "失敗を返すこと" do
        result = described_class.call(task_id: "abc")
        expect(result.success?).to be false
        expect(result.errors).to include("Task is not a number")
      end
    end
  end
end
