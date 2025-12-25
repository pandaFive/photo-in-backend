# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Areas::Update, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:area) { create(:area, name: "東京") }

    let(:valid_params) { { id: area.id, name: "大阪" } }

    describe "正常系" do
      context "adminユーザーが有効なパラメータでエリアを更新する場合" do
        it "成功を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.errors).to be_empty
        end

        it "エリア名が更新されること" do
          result = described_class.new.call(valid_params, admin)

          expect(result.area.name).to eq("大阪")
        end

        it "DBが更新されること" do
          described_class.new.call(valid_params, admin)

          area.reload
          expect(area.name).to eq("大阪")
        end

        it "Presenterでレンダリングできること" do
          result = described_class.new.call(valid_params, admin)
          rendered = Presenters::AreaPresenter.render_area(result.area)

          expect(rendered[:id]).to eq(area.id)
          expect(rendered[:name]).to eq("大阪")
        end
      end

      context "params[:area][:name]形式の場合" do
        it "成功すること" do
          result = described_class.new.call({ id: area.id, area: { name: "名古屋" } }, admin)

          expect(result.success?).to be true
          expect(result.area.name).to eq("名古屋")
        end
      end

      context "nameがnilの場合" do
        it "更新されないこと" do
          original_name = area.name
          result = described_class.new.call({ id: area.id, name: nil }, admin)

          expect(result.success?).to be true
          area.reload
          expect(area.name).to eq(original_name)
        end
      end
    end

    describe "異常系" do
      context "バリデーションエラーの場合" do
        it "idが無効な場合、失敗を返すこと" do
          result = described_class.new.call({ id: "abc", name: "大阪" }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "nameが33文字の場合、失敗を返すこと" do
          result = described_class.new.call({ id: area.id, name: "a" * 33 }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "DBが更新されないこと" do
          original_name = area.name
          described_class.new.call({ id: area.id, name: "a" * 33 }, admin)

          area.reload
          expect(area.name).to eq(original_name)
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(valid_params, current_account) }

        it_behaves_like "admin only service"

        it "DBが更新されないこと" do
          original_name = area.name
          described_class.new.call(valid_params, member)

          area.reload
          expect(area.name).to eq(original_name)
        end
      end

      context "エリアが存在しない場合" do
        it "not_foundを返すこと" do
          result = described_class.new.call({ id: 999999, name: "大阪" }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors.first).to include("999999")
        end
      end

      context "ロックタイムアウトが発生した場合" do
        let(:mock_repository) { instance_double(Services::Areas::Repository) }

        before do
          allow(mock_repository).to receive(:find_by_id_with_lock).and_raise(ActiveRecord::LockWaitTimeout)
        end

        it "service_unavailableを返すこと" do
          result = described_class.new(repository: mock_repository).call(valid_params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:service_unavailable)
          expect(result.errors.first).to include("混雑")
        end
      end

      context "デッドロックが発生した場合" do
        let(:mock_repository) { instance_double(Services::Areas::Repository) }

        before do
          allow(mock_repository).to receive(:find_by_id_with_lock).and_raise(ActiveRecord::Deadlocked)
        end

        it "service_unavailableを返すこと" do
          result = described_class.new(repository: mock_repository).call(valid_params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:service_unavailable)
        end
      end

      context "データベースエラーが発生した場合" do
        let(:mock_repository) { instance_double(Services::Areas::Repository) }

        before do
          allow(mock_repository).to receive(:find_by_id_with_lock).and_raise(ActiveRecord::StatementInvalid.new("Database error"))
        end

        it "internal_server_errorを返すこと" do
          result = described_class.new(repository: mock_repository).call(valid_params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:internal_server_error)
          expect(result.errors).to include("データベースエラーが発生しました")
        end
      end
    end
  end
end
