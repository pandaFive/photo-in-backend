# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Areas::Destroy, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:area) { create(:area, name: "東京") }

    let(:valid_params) { { id: area.id } }

    describe "正常系" do
      context "adminユーザーが削除する場合" do
        it "成功を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.message).to eq("deleted")
          expect(result.errors).to be_empty
        end

        it "エリアが削除されること" do
          expect {
            described_class.new.call(valid_params, admin)
          }.to change(Area, :count).by(-1)
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

        it "エリアが削除されないこと" do
          expect {
            described_class.new.call({ id: "abc" }, admin)
          }.not_to change(Area, :count)
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(valid_params, current_account) }

        it_behaves_like "admin only service"

        it "エリアが削除されないこと" do
          expect {
            described_class.new.call(valid_params, member)
          }.not_to change(Area, :count)
        end
      end

      context "エリアが存在しない場合" do
        it "not_foundを返すこと" do
          result = described_class.new.call({ id: 999999 }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors.first).to include("999999")
        end
      end

      context "FK制約違反の場合" do
        let!(:area_with_account) { create(:area, name: "大阪") }

        before do
          # エリアにアカウントを紐付ける
          admin.areas << area_with_account
        end

        it "conflictを返すこと" do
          result = described_class.new.call({ id: area_with_account.id }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:conflict)
          expect(result.errors.first).to include("アカウントが関連付けられている")
        end

        it "エリアが削除されないこと" do
          expect {
            described_class.new.call({ id: area_with_account.id }, admin)
          }.not_to change(Area, :count)
        end
      end
    end
  end
end
