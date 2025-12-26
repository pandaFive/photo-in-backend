# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tags::Destroy, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:tag) { create(:tag, name: "緊急") }

    let(:valid_params) { { id: tag.id } }

    describe "正常系" do
      context "adminユーザーが削除する場合" do
        it "成功を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.message).to eq("deleted")
          expect(result.errors).to be_empty
        end

        it "タグが削除されること" do
          expect {
            described_class.new.call(valid_params, admin)
          }.to change(Tag, :count).by(-1)
        end

        it "Presenterでレンダリングできること" do
          result = described_class.new.call(valid_params, admin)

          expect({ message: result.message }).to eq({ message: "deleted" })
        end
      end
    end

    describe "異常系" do
      context "バリデーションエラーの場合" do
        it "idが無効な場合、失敗を返すこと" do
          result = described_class.new.call({ id: "abc" }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "タグが削除されないこと" do
          expect {
            described_class.new.call({ id: "abc" }, admin)
          }.not_to change(Tag, :count)
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(valid_params, current_account) }

        it_behaves_like "admin only service"

        it "タグが削除されないこと" do
          expect {
            described_class.new.call(valid_params, member)
          }.not_to change(Tag, :count)
        end
      end

      context "タグが存在しない場合" do
        it "not_foundを返すこと" do
          result = described_class.new.call({ id: 999999 }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors.first).to include("999999")
        end
      end

      context "FK制約違反の場合" do
        let!(:tag_with_account) { create(:tag, name: "重要") }

        before do
          # タグにアカウントを紐付ける
          admin.tags << tag_with_account
        end

        it "conflictを返すこと" do
          result = described_class.new.call({ id: tag_with_account.id }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:conflict)
          expect(result.errors.first).to include("アカウントまたはタスクが関連付けられている")
        end

        it "タグが削除されないこと" do
          expect {
            described_class.new.call({ id: tag_with_account.id }, admin)
          }.not_to change(Tag, :count)
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
          expect(result.errors.first).to include("混雑")
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
