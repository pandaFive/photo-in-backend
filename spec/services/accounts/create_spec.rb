# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Accounts::Create, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:area) { create(:area, name: "Tokyo") }

    let(:valid_params) do
      {
        name: "Test User",
        password: "password123",
        role: "member",
        capacity: 5,
        area: [area.id]
      }
    end

    describe "正常系" do
      context "adminユーザーが有効なパラメータでアカウントを作成する場合" do
        it "成功してアカウントを作成すること" do
          expect {
            described_class.new.call(valid_params, admin)
          }.to change(Account, :count).by(1)
        end

        it "作成されたアカウント情報を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:created)
          expect(result.account.name).to eq("Test User")
          expect(result.account.role).to eq("member")
          expect(result.account.capacity).to eq(5)
          expect(result.errors).to be_empty
        end

        it "アカウントにエリアが紐付けられること" do
          result = described_class.new.call(valid_params, admin)

          expect(result.account.areas).to include(area)
        end

        it "Presenterでレンダリングした結果がlegacy実装と同じ形式であること" do
          result = described_class.new.call(valid_params, admin)
          rendered = Presenters::AccountPresenter.render_auth(result.account)

          expect(rendered).to have_key(:account)
          expect(rendered[:account]).to include(
            id: result.account.id,
            role: "member",
            name: "Test User"
          )
          expect(rendered[:account]).to have_key(:token)
        end
      end

      context "capacityを指定しない場合" do
        it "デフォルト値0でアカウントが作成されること" do
          params = valid_params.merge(capacity: nil)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
          expect(result.account.capacity).to eq(0)
        end
      end

      context "capacity境界値テスト" do
        it "capacityが0の場合、成功すること" do
          params = valid_params.merge(capacity: 0)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
          expect(result.account.capacity).to eq(0)
        end

        it "capacityが大きな値の場合、成功すること" do
          params = valid_params.merge(capacity: 100)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
          expect(result.account.capacity).to eq(100)
        end
      end

      context "空のエリア配列の場合" do
        it "エリアなしでアカウントが作成されること" do
          params = valid_params.merge(area: [])
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
          expect(result.account.areas).to be_empty
        end

        it "エリアがnilでもアカウントが作成されること" do
          params = valid_params.merge(area: nil)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
          expect(result.account.areas).to be_empty
        end
      end

      context "重複する名前の場合" do
        it "同名のアカウントを作成できること" do
          # 既存のアカウントと同じ名前で作成
          params = valid_params.merge(name: admin.name)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be true
          expect(result.account.name).to eq(admin.name)
        end
      end
    end

    describe "異常系" do
      context "バリデーションエラーの場合" do
        it "nameが空の場合、失敗を返すこと" do
          params = valid_params.merge(name: nil)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
          expect(result.errors).not_to be_empty
        end

        it "passwordが短すぎる場合、失敗を返すこと" do
          params = valid_params.merge(password: "short")
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "roleが無効な値の場合、失敗を返すこと" do
          params = valid_params.merge(role: "invalid")
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "nameが32文字を超える場合、失敗を返すこと" do
          params = valid_params.merge(name: "a" * 33)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "capacityが負の値の場合、失敗を返すこと" do
          params = valid_params.merge(capacity: -1)
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(valid_params, current_account) }

        it_behaves_like "admin only service"

        it "アカウントが作成されないこと" do
          expect {
            described_class.new.call(valid_params, member)
          }.not_to change(Account, :count)
        end
      end

      context "存在しないエリアが指定された場合" do
        it "not_foundを返すこと" do
          params = valid_params.merge(area: [999999])
          result = described_class.new.call(params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors.first).to include("エリアが見つかりません")
        end

        it "アカウントが作成されないこと" do
          params = valid_params.merge(area: [999999])
          expect {
            described_class.new.call(params, admin)
          }.not_to change(Account, :count)
        end
      end

      context "saveが失敗した場合" do
        it "AccountAreaレコードが作成されないこと" do
          # saveが失敗するモックリポジトリを作成
          mock_repository = instance_double(Services::Accounts::Repository)
          account = Account.new(name: "Test", password: "password123", role: "member")

          allow(mock_repository).to receive(:build).and_return(account)
          allow(mock_repository).to receive(:find_areas).and_return([area])
          allow(mock_repository).to receive(:assign_areas) do |acc, areas|
            acc.areas = areas
          end
          allow(mock_repository).to receive(:save).and_return(false)

          expect {
            described_class.new(repository: mock_repository).call(valid_params, admin)
          }.not_to change(AccountArea, :count)
        end

        it "失敗結果を返すこと" do
          mock_repository = instance_double(Services::Accounts::Repository)
          account = Account.new(name: "Test", password: "password123", role: "member")
          account.errors.add(:base, "保存に失敗しました")

          allow(mock_repository).to receive(:build).and_return(account)
          allow(mock_repository).to receive(:find_areas).and_return([area])
          allow(mock_repository).to receive(:assign_areas)
          allow(mock_repository).to receive(:save).and_return(false)

          result = described_class.new(repository: mock_repository).call(valid_params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end
      end
    end

    describe "リファクタリング前後の入出力等価性" do
      it "バリデーション → ポリシー → エリア検索 → 作成の順序で処理されること" do
        # バリデーションエラーはポリシーチェック前に返される
        result_invalid = described_class.new.call({ name: nil }, member)
        expect(result_invalid.status).to eq(:unprocessable_entity)

        # ポリシーエラーはエリア検索前に返される
        result_forbidden = described_class.new.call(valid_params, member)
        expect(result_forbidden.status).to eq(:forbidden)

        # 存在しないエリアはnot_foundを返す
        params_invalid_area = valid_params.merge(area: [999999])
        result_not_found = described_class.new.call(params_invalid_area, admin)
        expect(result_not_found.status).to eq(:not_found)
      end

      it "成功時のレスポンス構造がlegacyと一致すること" do
        result = described_class.new.call(valid_params, admin)
        rendered = Presenters::AccountPresenter.render_auth(result.account)

        # legacy: render json: ::Presenters::AccountPresenter.render_auth(result.account)
        expect(rendered[:account]).to have_key(:id)
        expect(rendered[:account]).to have_key(:role)
        expect(rendered[:account]).to have_key(:token)
        expect(rendered[:account]).to have_key(:name)
      end
    end
  end
end
