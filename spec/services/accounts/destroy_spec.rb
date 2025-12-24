# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Accounts::Destroy, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:target_account) { create(:account_member, name: "to_be_deleted") }

    let(:valid_params) do
      { id: target_account.id }
    end

    describe "正常系" do
      context "adminユーザーが存在するアカウントを削除する場合" do
        it "成功を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.errors).to be_empty
        end

        it "アカウントがDBから削除されること" do
          expect {
            described_class.new.call(valid_params, admin)
          }.to change(Account, :count).by(-1)
        end

        it "削除されたアカウントが検索できないこと" do
          described_class.new.call(valid_params, admin)

          expect(Account.find_by(id: target_account.id)).to be_nil
        end

        it "legacy実装と同じレスポンス形式であること" do
          result = described_class.new.call(valid_params, admin)

          # legacy: render json: { message: "deleted" }, status: 200
          expect(result.message).to eq("deleted")
        end
      end
    end

    describe "異常系" do
      context "バリデーションエラーの場合" do
        it "idが空の場合、失敗を返すこと" do
          params = { id: nil }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
          expect(result.errors).not_to be_empty
        end

        it "idが数値でない場合、失敗を返すこと" do
          params = { id: "abc" }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "アカウントが削除されないこと" do
          params = { id: nil }
          expect {
            described_class.new.call(params, admin)
          }.not_to change(Account, :count)
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(valid_params, current_account) }

        it_behaves_like "admin only service"

        it "アカウントが削除されないこと" do
          expect {
            described_class.new.call(valid_params, member)
          }.not_to change(Account, :count)
        end
      end

      context "アカウントが存在しない場合" do
        it "not_foundを返すこと" do
          params = { id: 999999 }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors.first).to include("999999")
        end

        it "他のアカウントが削除されないこと" do
          params = { id: 999999 }
          expect {
            described_class.new.call(params, admin)
          }.not_to change(Account, :count)
        end
      end
    end

    describe "リファクタリング前後の入出力等価性" do
      it "バリデーション → ポリシー → 検索 → 削除の順序で処理されること" do
        # バリデーションエラーはポリシーチェック前に返される
        result_invalid = described_class.new.call({ id: nil }, member)
        expect(result_invalid.status).to eq(:unprocessable_entity)

        # ポリシーエラーは存在チェック前に返される
        result_forbidden = described_class.new.call({ id: 999999 }, member)
        expect(result_forbidden.status).to eq(:forbidden)

        # 存在しないアカウントはnot_foundを返す
        result_not_found = described_class.new.call({ id: 999999 }, admin)
        expect(result_not_found.status).to eq(:not_found)
      end

      it "削除成功時のレスポンスがlegacy実装と同じ構造であること" do
        result = described_class.new.call(valid_params, admin)

        # legacy: render json: { message: "deleted" }, status: 200
        expect(result.message).to eq("deleted")
        expect(result.status).to eq(:ok)
      end
    end

    describe "関連データの処理" do
      let!(:area) { create(:area) }

      before do
        target_account.add_area(area)
      end

      it "関連account_areasがある場合、ForeignKeyViolationエラーになること（legacy動作と同等）" do
        # legacy実装も外部キー制約エラーを処理しないため、例外が発生する
        expect {
          described_class.new.call(valid_params, admin)
        }.to raise_error(ActiveRecord::InvalidForeignKey)
      end

      it "エラー発生時にアカウントが削除されないこと" do
        expect {
          described_class.new.call(valid_params, admin) rescue nil
        }.not_to change(Account, :count)
      end
    end
  end
end
