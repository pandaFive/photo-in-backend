# frozen_string_literal: true

RSpec.shared_examples "admin only service" do
  context "memberユーザーの場合" do
    it "forbiddenを返すこと" do
      expect(result.success?).to be false
      expect(result.status).to eq(:forbidden)
      expect(result.errors).to include("権限がありません")
    end
  end

  context "current_accountがnilの場合" do
    let(:current_account) { nil }

    it "forbiddenを返すこと" do
      expect(result.success?).to be false
      expect(result.status).to eq(:forbidden)
    end
  end
end
