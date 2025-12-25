# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::UnfulfilledsCount, type: :service do
  let(:repository) { instance_double(Services::Tasks::Repository) }
  let(:service) { described_class.new(repository:) }

  describe "#call" do
    let!(:admin) { create(:account) }
    let!(:member) { create(:account_member) }

    context "認証されていない場合" do
      it "unauthorizedを返すこと" do
        result = service.call(nil)
        expect(result.success?).to be false
        expect(result.status).to eq(:unauthorized)
        expect(result.errors).to include("認証が必要です")
      end

      it "countがnilであること" do
        result = service.call(nil)
        expect(result.count).to be_nil
      end
    end

    context "管理者で認証されている場合" do
      before do
        allow(repository).to receive(:count_unfulfilleds).and_return(5)
      end

      it "成功を返すこと" do
        result = service.call(admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "カウントを返すこと" do
        result = service.call(admin)
        expect(result.count).to eq(5)
      end

      it "repository.count_unfulfilledsを呼び出すこと" do
        service.call(admin)
        expect(repository).to have_received(:count_unfulfilleds)
      end
    end

    context "一般メンバーで認証されている場合" do
      before do
        allow(repository).to receive(:count_unfulfilleds).and_return(3)
      end

      it "成功を返すこと（認可なし - 読み取り専用）" do
        result = service.call(member)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "カウントを返すこと" do
        result = service.call(member)
        expect(result.count).to eq(3)
      end
    end

    context "カウントが0の場合" do
      before do
        allow(repository).to receive(:count_unfulfilleds).and_return(0)
      end

      it "成功を返すこと" do
        result = service.call(admin)
        expect(result.success?).to be true
      end

      it "0を返すこと" do
        result = service.call(admin)
        expect(result.count).to eq(0)
      end
    end
  end

  describe "依存性注入" do
    it "デフォルトでRepositoryを使用すること" do
      service = described_class.new
      expect(service.instance_variable_get(:@repository)).to be_a(Services::Tasks::Repository)
    end

    it "カスタムRepositoryを注入できること" do
      custom_repo = instance_double(Services::Tasks::Repository)
      service = described_class.new(repository: custom_repo)
      expect(service.instance_variable_get(:@repository)).to eq(custom_repo)
    end
  end
end
