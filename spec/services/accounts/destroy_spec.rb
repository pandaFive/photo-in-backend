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

      it "関連account_areasがある場合、conflictを返すこと" do
        result = described_class.new.call(valid_params, admin)

        expect(result.success?).to be false
        expect(result.status).to eq(:conflict)
        expect(result.errors).to include("このアカウントには関連データ（タスク割当、コメント等）が存在するため削除できません")
      end

      it "エラー発生時にアカウントが削除されないこと" do
        expect {
          described_class.new.call(valid_params, admin)
        }.not_to change(Account, :count)
      end
    end

    describe "自己削除防止" do
      context "管理者が自分自身を削除しようとした場合" do
        it "forbiddenを返すこと" do
          result = described_class.new.call({ id: admin.id }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:forbidden)
          expect(result.errors).to include("自分自身のアカウントは削除できません")
        end

        it "アカウントが削除されないこと" do
          expect {
            described_class.new.call({ id: admin.id }, admin)
          }.not_to change(Account, :count)
        end
      end
    end

    describe "最後の管理者削除防止" do
      context "最後の管理者を削除しようとした場合" do
        let!(:only_admin) { create(:account, role: "admin") }
        let!(:target_admin) { create(:account, role: "admin") }

        before do
          # 既存のadminを削除して、only_adminとtarget_adminだけにする
          admin.destroy
        end

        it "管理者が2人以上いる場合は削除可能であること" do
          result = described_class.new.call({ id: target_admin.id }, only_admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
        end

        it "管理者が1人だけの場合はforbiddenを返すこと" do
          # target_adminを削除してonly_adminだけにする
          target_admin.destroy

          # 新しいターゲット管理者を作成
          new_target = create(:account, role: "admin")

          # この時点で管理者は2人（only_admin, new_target）
          # new_targetを削除
          described_class.new.call({ id: new_target.id }, only_admin)

          # only_adminが最後の1人になった状態で、別のメンバーを作成
          create(:account_member)

          # only_adminが自分自身を削除しようとしても自己削除防止が先に働く
          result = described_class.new.call({ id: only_admin.id }, only_admin)
          expect(result.status).to eq(:forbidden)
          expect(result.errors).to include("自分自身のアカウントは削除できません")
        end

        it "他の管理者が最後の管理者を削除しようとした場合はforbiddenを返すこと" do
          # only_adminとtarget_adminの2人
          # target_adminを削除してonly_adminだけにする
          target_admin.destroy

          # 新しい管理者を作成（削除する側）
          deleter_admin = create(:account, role: "admin")

          # only_adminは最後の管理者ではなくなった（deleter_adminがいる）
          # deleter_adminがonly_adminを削除しても、まだdeleter_adminがいるのでOK
          result = described_class.new.call({ id: only_admin.id }, deleter_admin)
          expect(result.success?).to be true

          # deleter_adminが最後の1人になった
          # deleter_adminが自分を削除しようとすると自己削除防止
          result = described_class.new.call({ id: deleter_admin.id }, deleter_admin)
          expect(result.status).to eq(:forbidden)
        end
      end
    end
  end
end
