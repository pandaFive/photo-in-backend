# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::GetCompleteData, type: :service do
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

      it "dataがnilであること" do
        result = service.call(nil)
        expect(result.data).to be_nil
      end
    end

    context "管理者で認証されている場合" do
      let(:sample_data) { { "12月20日" => 3, "12月21日" => 5 } }

      before do
        allow(repository).to receive(:get_completed_past_week).and_return(sample_data)
      end

      it "成功を返すこと" do
        result = service.call(admin)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "データを返すこと" do
        result = service.call(admin)
        expect(result.data).to eq(sample_data)
      end

      it "repository.get_completed_past_weekを呼び出すこと" do
        service.call(admin)
        expect(repository).to have_received(:get_completed_past_week)
      end
    end

    context "一般メンバーで認証されている場合" do
      let(:sample_data) { { "12月22日" => 2 } }

      before do
        allow(repository).to receive(:get_completed_past_week).and_return(sample_data)
      end

      it "成功を返すこと（認可なし - 読み取り専用）" do
        result = service.call(member)
        expect(result.success?).to be true
        expect(result.status).to eq(:ok)
      end

      it "データを返すこと" do
        result = service.call(member)
        expect(result.data).to eq(sample_data)
      end
    end

    context "データが空の場合" do
      before do
        allow(repository).to receive(:get_completed_past_week).and_return({})
      end

      it "成功を返すこと" do
        result = service.call(admin)
        expect(result.success?).to be true
      end

      it "空のハッシュを返すこと" do
        result = service.call(admin)
        expect(result.data).to eq({})
      end
    end

    context "データベース接続エラーの場合" do
      before do
        allow(repository).to receive(:get_completed_past_week).and_raise(ActiveRecord::ConnectionNotEstablished)
        allow(Rails.logger).to receive(:error)
      end

      it "失敗を返すこと" do
        result = service.call(admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:service_unavailable)
      end

      it "エラーメッセージを返すこと" do
        result = service.call(admin)
        expect(result.errors).to include("データベース接続に失敗しました。しばらくしてから再試行してください。")
      end

      it "エラーをログに記録すること" do
        service.call(admin)
        expect(Rails.logger).to have_received(:error).with(hash_including(message: "データベース接続失敗"))
      end
    end

    context "データベースクエリエラーの場合" do
      before do
        allow(repository).to receive(:get_completed_past_week).and_raise(ActiveRecord::StatementInvalid.new("query error"))
        allow(Rails.logger).to receive(:error)
      end

      it "失敗を返すこと" do
        result = service.call(admin)
        expect(result.success?).to be false
        expect(result.status).to eq(:internal_server_error)
      end

      it "エラーメッセージを返すこと" do
        result = service.call(admin)
        expect(result.errors).to include("データの取得に失敗しました。")
      end

      it "エラーをログに記録すること" do
        service.call(admin)
        expect(Rails.logger).to have_received(:error).with(hash_including(message: "データベースクエリ失敗"))
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
