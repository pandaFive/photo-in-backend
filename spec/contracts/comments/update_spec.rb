# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Comments::Update, type: :model do
  describe ".call" do
    context "有効なパラメータの場合" do
      it "成功を返すこと" do
        result = described_class.call(id: 1, comment: { content: "更新コメント" })
        expect(result.success?).to be true
      end

      it "正規化された値を返すこと" do
        result = described_class.call(id: "5", comment: { content: "更新コメント" })
        expect(result.value[:id]).to eq 5
        expect(result.value[:content]).to eq "更新コメント"
      end
    end

    context "contentがnilの場合" do
      it "成功を返すこと（任意項目）" do
        result = described_class.call(id: 1, comment: { content: nil })
        expect(result.success?).to be true
      end

      it "nilはcompactで除外されること" do
        result = described_class.call(id: 1, comment: { content: nil })
        expect(result.value).not_to have_key(:content)
      end
    end

    context "contentが1000文字を超える場合" do
      it "失敗を返すこと" do
        result = described_class.call(id: 1, comment: { content: "a" * 1001 })
        expect(result.success?).to be false
        expect(result.errors).to include("Content is too long (maximum is 1000 characters)")
      end
    end

    context "idがnilの場合" do
      it "失敗を返すこと" do
        result = described_class.call(id: nil, comment: { content: "テスト" })
        expect(result.success?).to be false
        expect(result.errors).to include("Id can't be blank")
      end
    end

    context "idが0の場合" do
      it "失敗を返すこと" do
        result = described_class.call(id: 0, comment: { content: "テスト" })
        expect(result.success?).to be false
        expect(result.errors).to include("Id must be greater than 0")
      end
    end

    context "idが文字列の場合" do
      it "失敗を返すこと" do
        result = described_class.call(id: "abc", comment: { content: "テスト" })
        expect(result.success?).to be false
        expect(result.errors).to include("Id is not a number")
      end
    end

    context "commentパラメータがない場合" do
      it "成功を返すこと（更新項目なし）" do
        result = described_class.call(id: 1)
        expect(result.success?).to be true
      end
    end
  end
end
