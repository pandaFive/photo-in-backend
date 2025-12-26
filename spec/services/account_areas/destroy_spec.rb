# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::AccountAreas::Destroy, type: :service do
  let(:repository) { instance_double(Services::AccountAreas::Repository) }
  let(:service) { described_class.new(repository:) }

  describe "#call" do
    let!(:admin) { create(:account) }
    let!(:member) { create(:account_member) }
    let!(:target_account) { create(:account_member) }
    let!(:area) { create(:area) }

    let(:valid_params) { { account_id: target_account.id.to_s, area_id: area.id.to_s } }

    context "認証されていない場合" do
      it "unauthorizedを返すこと" do
        result = service.call(valid_params, nil)
        expect(result.success?).to be false
        expect(result.status).to eq(:unauthorized)
        expect(result.errors).to include("認証が必要です")
      end
    end

    context "管理者ではない場合" do
      it "forbiddenを返すこと" do
        result = service.call(valid_params, member)
        expect(result.success?).to be false
        expect(result.status).to eq(:forbidden)
        expect(result.errors).to include("権限がありません")
      end
    end

    context "Contract検証に失敗した場合" do
      let(:invalid_params) { { account_id: "invalid", area_id: area.id.to_s } }

      it "unprocessable_entityを返すこと" do
        result = service.call(invalid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
      end
    end

    context "アカウントが存在しない場合" do
      before do
        allow(repository).to receive(:find_account).with(999999).and_return(nil)
      end

      it "not_foundを返すこと" do
        result = service.call({ account_id: "999999", area_id: area.id.to_s }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:not_found)
        expect(result.errors).to include("アカウントが見つかりません")
      end
    end

    context "エリアが存在しない場合" do
      before do
        allow(repository).to receive(:find_account).with(target_account.id).and_return(target_account)
        allow(repository).to receive(:find_area).with(999999).and_return(nil)
      end

      it "not_foundを返すこと" do
        result = service.call({ account_id: target_account.id.to_s, area_id: "999999" }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:not_found)
        expect(result.errors).to include("エリアが見つかりません")
      end
    end

    context "エリアが紐付いていない場合" do
      before do
        allow(repository).to receive(:find_account).with(target_account.id).and_return(target_account)
        allow(repository).to receive(:find_area).with(area.id).and_return(area)
        allow(repository).to receive(:area_exists?).with(target_account, area).and_return(false)
      end

      it "not_foundを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:not_found)
        expect(result.errors).to include("このエリアはアカウントに紐付いていません")
      end
    end

    context "正常にエリアを削除した場合" do
      let(:areas) { [] }

      before do
        allow(repository).to receive(:find_account).with(target_account.id).and_return(target_account)
        allow(repository).to receive(:find_area).with(area.id).and_return(area)
        allow(repository).to receive(:area_exists?).with(target_account, area).and_return(true)
        allow(repository).to receive(:remove_area).with(target_account, area).and_return(true)
        allow(repository).to receive(:get_areas).with(target_account).and_return(areas)
      end

      it "成功を返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "areasを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.areas).to eq(areas)
      end

      it "remove_areaを呼び出すこと" do
        service.call(valid_params, admin)
        expect(repository).to have_received(:remove_area).with(target_account, area)
      end
    end
  end

  describe "依存性注入" do
    it "デフォルトでRepositoryを使用すること" do
      service = described_class.new
      expect(service.instance_variable_get(:@repository)).to be_a(Services::AccountAreas::Repository)
    end

    it "カスタムRepositoryを注入できること" do
      custom_repo = instance_double(Services::AccountAreas::Repository)
      service = described_class.new(repository: custom_repo)
      expect(service.instance_variable_get(:@repository)).to eq(custom_repo)
    end
  end
end
