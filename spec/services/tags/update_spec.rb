# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tags::Update, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:tag) { create(:tag, name: "緊急") }

    let(:valid_params) { { id: tag.id, name: "重要" } }

    describe "正常系" do
      context "adminユーザーが有効なパラメータでタグを更新する場合" do
        it "成功を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.errors).to be_empty
        end

        it "タグ名が更新されること" do
          result = described_class.new.call(valid_params, admin)

          expect(result.tag.name).to eq("重要")
        end

        it "DBが更新されること" do
          described_class.new.call(valid_params, admin)

          tag.reload
          expect(tag.name).to eq("重要")
        end

        it "Presenterでレンダリングできること" do
          result = described_class.new.call(valid_params, admin)
          rendered = Presenters::TagPresenter.render_tag(result.tag)

          expect(rendered[:id]).to eq(tag.id)
          expect(rendered[:name]).to eq("重要")
        end
      end

      context "params[:tag][:name]形式の場合" do
        it "成功すること" do
          result = described_class.new.call({ id: tag.id, tag: { name: "高優先" } }, admin)

          expect(result.success?).to be true
          expect(result.tag.name).to eq("高優先")
        end
      end

      context "nameがnilの場合" do
        it "更新されないこと" do
          original_name = tag.name
          result = described_class.new.call({ id: tag.id, name: nil }, admin)

          expect(result.success?).to be true
          tag.reload
          expect(tag.name).to eq(original_name)
        end
      end
    end

    describe "異常系" do
      context "バリデーションエラーの場合" do
        it "idが無効な場合、失敗を返すこと" do
          result = described_class.new.call({ id: "abc", name: "重要" }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "nameが33文字の場合、失敗を返すこと" do
          result = described_class.new.call({ id: tag.id, name: "a" * 33 }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "DBが更新されないこと" do
          original_name = tag.name
          described_class.new.call({ id: tag.id, name: "a" * 33 }, admin)

          tag.reload
          expect(tag.name).to eq(original_name)
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(valid_params, current_account) }

        it_behaves_like "admin only service"

        it "DBが更新されないこと" do
          original_name = tag.name
          described_class.new.call(valid_params, member)

          tag.reload
          expect(tag.name).to eq(original_name)
        end
      end

      context "タグが存在しない場合" do
        it "not_foundを返すこと" do
          result = described_class.new.call({ id: 999999, name: "重要" }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors.first).to include("999999")
        end
      end

      context "ロックタイムアウトが発生した場合" do
        let(:mock_repository) { instance_double(Services::Tags::Repository) }

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
        let(:mock_repository) { instance_double(Services::Tags::Repository) }

        before do
          allow(mock_repository).to receive(:find_by_id_with_lock).and_raise(ActiveRecord::Deadlocked)
        end

        it "service_unavailableを返すこと" do
          result = described_class.new(repository: mock_repository).call(valid_params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:service_unavailable)
        end
      end

      context "一意性制約違反の場合" do
        let(:mock_repository) { instance_double(Services::Tags::Repository) }

        before do
          allow(mock_repository).to receive(:find_by_id_with_lock).and_raise(ActiveRecord::RecordNotUnique.new("Duplicate entry"))
        end

        it "conflictを返すこと" do
          result = described_class.new(repository: mock_repository).call(valid_params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:conflict)
          expect(result.errors).to include("このタグは既に存在します")
        end
      end

      context "データベースエラーが発生した場合" do
        let(:mock_repository) { instance_double(Services::Tags::Repository) }

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
