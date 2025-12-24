# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Accounts::Show, type: :service do
  describe "#call" do
    let(:admin) { create(:account, role: "admin") }
    let(:member) { create(:account_member) }
    let(:target_account) { create(:account_member, name: "target_member") }

    describe "正常系" do
      context "adminユーザーが存在するアカウントを参照する場合" do
        it "成功してアカウント情報を返すこと" do
          result = described_class.new.call({ id: target_account.id }, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.account).to eq(target_account)
          expect(result.errors).to be_empty
        end

        it "Presenterでレンダリングした結果がlegacy実装と同じ形式であること" do
          result = described_class.new.call({ id: target_account.id }, admin)
          rendered = Presenters::AccountPresenter.render_account(result.account)

          expect(rendered).to include(
            id: target_account.id,
            capacity: target_account.capacity,
            name: target_account.name
          )
          expect(rendered).to have_key(:createdAt)
          expect(rendered).to have_key(:updatedAt)
        end
      end
    end

    describe "異常系" do
      context "バリデーションエラーの場合" do
        it "idが空の場合、失敗を返すこと" do
          result = described_class.new.call({ id: nil }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
          expect(result.errors).not_to be_empty
        end

        it "idが数値でない場合、失敗を返すこと" do
          result = described_class.new.call({ id: "abc" }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
          expect(result.errors).not_to be_empty
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call({ id: target_account.id }, current_account) }

        it_behaves_like "admin only service"
      end

      context "アカウントが存在しない場合" do
        it "not_foundを返すこと" do
          result = described_class.new.call({ id: 999999 }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors.first).to include("999999")
        end
      end
    end

    describe "リファクタリング前後の入出力等価性" do
      it "バリデーション → ポリシー → 検索の順序で処理されること" do
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
    end
  end
end
