# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Areas::Index, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:area1) { create(:area, name: "東京") }
    let!(:area2) { create(:area, name: "大阪") }

    describe "正常系" do
      context "adminユーザーの場合" do
        it "成功を返すこと" do
          result = described_class.new.call(admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.errors).to be_empty
        end

        it "全エリアを返すこと" do
          result = described_class.new.call(admin)

          expect(result.areas.length).to eq(2)
        end

        it "Presenterでレンダリングできること" do
          result = described_class.new.call(admin)
          rendered = Presenters::AreaPresenter.render_areas(result.areas)

          expect(rendered).to be_an(Array)
          expect(rendered.first).to have_key(:id)
          expect(rendered.first).to have_key(:name)
        end
      end

      context "memberユーザーの場合" do
        it "成功を返すこと" do
          result = described_class.new.call(member)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
        end
      end
    end

    describe "異常系" do
      context "current_accountがnilの場合" do
        it "unauthorizedを返すこと" do
          result = described_class.new.call(nil)

          expect(result.success?).to be false
          expect(result.status).to eq(:unauthorized)
          expect(result.errors).to include("認証が必要です")
        end
      end

      context "データベースエラーが発生した場合" do
        let(:mock_repository) { instance_double(Services::Areas::Repository) }

        before do
          allow(mock_repository).to receive(:all_areas).and_raise(ActiveRecord::StatementInvalid.new("Database error"))
        end

        it "internal_server_errorを返すこと" do
          result = described_class.new(repository: mock_repository).call(admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:internal_server_error)
          expect(result.errors).to include("データベースエラーが発生しました")
        end
      end
    end
  end
end
