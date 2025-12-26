# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::TagAccounts::Create, type: :service do
  let(:repository) { instance_double(Services::TagAccounts::Repository) }
  let(:service) { described_class.new(repository:) }

  describe "#call" do
    let!(:admin) { create(:account) }
    let!(:member) { create(:account_member) }
    let!(:target_account) { create(:account_member) }
    let!(:tag) { create(:tag) }

    let(:valid_params) { { account_id: target_account.id.to_s, tag_id: tag.id.to_s } }

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
      let(:invalid_params) { { account_id: "invalid", tag_id: tag.id.to_s } }

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
        result = service.call({ account_id: "999999", tag_id: tag.id.to_s }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:not_found)
        expect(result.errors).to include("アカウントが見つかりません")
      end
    end

    context "タグが存在しない場合" do
      before do
        allow(repository).to receive(:find_account).with(target_account.id).and_return(target_account)
        allow(repository).to receive(:find_tag).with(999999).and_return(nil)
      end

      it "not_foundを返すこと" do
        result = service.call({ account_id: target_account.id.to_s, tag_id: "999999" }, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:not_found)
        expect(result.errors).to include("タグが見つかりません")
      end
    end

    context "タグが既に追加されている場合" do
      before do
        allow(repository).to receive(:find_account).with(target_account.id).and_return(target_account)
        allow(repository).to receive(:find_tag).with(tag.id).and_return(tag)
        allow(repository).to receive(:tag_exists?).with(target_account, tag).and_return(true)
      end

      it "conflictを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:conflict)
        expect(result.errors).to include("このタグは既に追加されています")
      end
    end

    context "正常にタグを追加した場合" do
      let(:tags) { [tag] }

      before do
        allow(repository).to receive(:find_account).with(target_account.id).and_return(target_account)
        allow(repository).to receive(:find_tag).with(tag.id).and_return(tag)
        allow(repository).to receive(:tag_exists?).with(target_account, tag).and_return(false)
        allow(repository).to receive(:add_tag).with(target_account, tag).and_return(true)
        allow(repository).to receive(:get_tags).with(target_account).and_return(tags)
      end

      it "成功を返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "tagsを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.tags).to eq(tags)
      end

      it "add_tagを呼び出すこと" do
        service.call(valid_params, admin)
        expect(repository).to have_received(:add_tag).with(target_account, tag)
      end
    end

    context "add_tagがfalseを返した場合（レースコンディション）" do
      before do
        allow(repository).to receive(:find_account).with(target_account.id).and_return(target_account)
        allow(repository).to receive(:find_tag).with(tag.id).and_return(tag)
        allow(repository).to receive(:tag_exists?).with(target_account, tag).and_return(false)
        allow(repository).to receive(:add_tag).with(target_account, tag).and_return(false)
      end

      it "unprocessable_entityを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.errors).to include("タグの追加に失敗しました")
      end
    end

    context "データベースエラーが発生した場合" do
      before do
        allow(repository).to receive(:find_account).with(target_account.id).and_return(target_account)
        allow(repository).to receive(:find_tag).with(tag.id).and_return(tag)
        allow(repository).to receive(:tag_exists?).with(target_account, tag).and_return(false)
        allow(repository).to receive(:add_tag).and_raise(ActiveRecord::StatementInvalid.new("connection lost"))
      end

      it "internal_server_errorを返すこと" do
        result = service.call(valid_params, admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:internal_server_error)
        expect(result.errors).to include("データベースエラーが発生しました")
      end
    end
  end

  describe "依存性注入" do
    it "デフォルトでRepositoryを使用すること" do
      service = described_class.new
      expect(service.instance_variable_get(:@repository)).to be_a(Services::TagAccounts::Repository)
    end

    it "カスタムRepositoryを注入できること" do
      custom_repo = instance_double(Services::TagAccounts::Repository)
      service = described_class.new(repository: custom_repo)
      expect(service.instance_variable_get(:@repository)).to eq(custom_repo)
    end
  end
end
