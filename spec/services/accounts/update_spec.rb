# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Accounts::Update, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:target_account) { create(:account_member, name: "original_name", capacity: 5) }

    let(:valid_params) do
      {
        id: target_account.id,
        name: "updated_name",
        capacity: 10
      }
    end

    describe "正常系" do
      context "adminユーザーが有効なパラメータで更新する場合" do
        it "成功してアカウントを更新すること" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.account.name).to eq("updated_name")
          expect(result.account.capacity).to eq(10)
          expect(result.errors).to be_empty
        end

        it "DBに変更が反映されていること" do
          described_class.new.call(valid_params, admin)

          target_account.reload
          expect(target_account.name).to eq("updated_name")
          expect(target_account.capacity).to eq(10)
        end

        it "updated_atが更新されること" do
          original_updated_at = target_account.updated_at
          sleep(0.01) # 時間差を確保
          described_class.new.call(valid_params, admin)
          target_account.reload
          expect(target_account.updated_at).to be >= original_updated_at
        end
      end

      context "一部のパラメータのみ更新する場合" do
        it "指定したパラメータのみ更新されること" do
          params = { id: target_account.id, name: "new_name" }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
          expect(result.account.name).to eq("new_name")
          expect(result.account.capacity).to eq(5) # 元の値のまま
        end
      end

      context "パスワード更新の場合" do
        it "パスワードを更新できること" do
          new_password = "newpassword123"
          params = { id: target_account.id, password: new_password }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
        end

        it "更新後のパスワードで認証できること" do
          new_password = "newpassword123"
          params = { id: target_account.id, password: new_password }
          described_class.new.call(params, admin)

          target_account.reload
          expect(target_account.authenticate(new_password)).to be_truthy
        end

        it "更新前のパスワードでは認証できないこと" do
          old_password = target_account.password
          new_password = "newpassword123"
          params = { id: target_account.id, password: new_password }
          described_class.new.call(params, admin)

          target_account.reload
          expect(target_account.authenticate(old_password)).to be_falsy
        end
      end

      context "capacity境界値テスト" do
        it "capacityを0に更新できること" do
          params = { id: target_account.id, capacity: 0 }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
          expect(result.account.capacity).to eq(0)
        end

        it "capacityを大きな値に更新できること" do
          params = { id: target_account.id, capacity: 100 }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
          expect(result.account.capacity).to eq(100)
        end
      end

      context "レスポンス形式の検証" do
        it "legacy実装と同じレスポンス形式であること" do
          result = described_class.new.call(valid_params, admin)

          # legacy: render json: account
          expect(result.account).to respond_to(:id)
          expect(result.account).to respond_to(:name)
          expect(result.account).to respond_to(:capacity)
          expect(result.account).to respond_to(:updated_at)
          expect(result.account).to respond_to(:created_at)
        end
      end
    end

    describe "異常系" do
      context "バリデーションエラーの場合" do
        it "idが空の場合、失敗を返すこと" do
          params = valid_params.merge(id: nil)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
          expect(result.errors).not_to be_empty
        end

        it "nameが32文字を超える場合、失敗を返すこと" do
          params = valid_params.merge(name: "a" * 33)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "DBが更新されないこと" do
          original_name = target_account.name
          params = valid_params.merge(name: "a" * 33)
          described_class.new.call(params, admin)

          target_account.reload
          expect(target_account.name).to eq(original_name)
        end

        it "capacityが負の値の場合、失敗を返すこと" do
          params = { id: target_account.id, capacity: -1 }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "パスワードが短すぎる場合、失敗を返すこと" do
          params = { id: target_account.id, password: "short" }
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(valid_params, current_account) }

        it_behaves_like "admin only service"

        it "DBが更新されないこと" do
          original_name = target_account.name
          described_class.new.call(valid_params, member)

          target_account.reload
          expect(target_account.name).to eq(original_name)
        end
      end

      context "アカウントが存在しない場合" do
        it "not_foundを返すこと" do
          params = valid_params.merge(id: 999999)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors.first).to include("999999")
        end
      end
    end

    describe "リファクタリング前後の入出力等価性" do
      it "バリデーション → ポリシー → 検索 → 更新の順序で処理されること" do
        # バリデーションエラーはポリシーチェック前に返される
        result_invalid = described_class.new.call({ id: nil }, member)
        expect(result_invalid.status).to eq(:unprocessable_entity)

        # ポリシーエラーは存在チェック前に返される
        result_forbidden = described_class.new.call({ id: 999999, name: "test" }, member)
        expect(result_forbidden.status).to eq(:forbidden)

        # 存在しないアカウントはnot_foundを返す
        result_not_found = described_class.new.call({ id: 999999, name: "test" }, admin)
        expect(result_not_found.status).to eq(:not_found)
      end

      it "更新成功時のレスポンスがlegacy実装と同じ構造であること" do
        result = described_class.new.call(valid_params, admin)

        # legacy: render json: account
        account_json = result.account.as_json
        expect(account_json).to have_key("id")
        expect(account_json).to have_key("name")
        expect(account_json).to have_key("capacity")
        expect(account_json).to have_key("updated_at")
      end
    end
  end
end
