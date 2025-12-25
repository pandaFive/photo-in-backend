# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Areas::Show, type: :contract do
  # IdContract を継承しているため、基本的なID検証は親クラスのテストでカバー
  describe "継承" do
    it "IdContract を継承していること" do
      expect(described_class.superclass).to eq(Contracts::Areas::IdContract)
    end
  end

  describe ".call" do
    it "正の整数IDで成功すること" do
      result = described_class.call({ id: 1 })

      expect(result.success?).to be true
      expect(result.value[:id]).to eq(1)
      expect(result.errors).to be_empty
    end

    it "idがnilの場合、失敗すること" do
      result = described_class.call({ id: nil })

      expect(result.success?).to be false
      expect(result.errors).not_to be_empty
    end
  end
end
