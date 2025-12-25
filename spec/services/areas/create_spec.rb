# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Areas::Create, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }

    let(:valid_params) { { name: "東京" } }

    describe "正常系" do
      context "adminユーザーが有効なパラメータでエリアを作成する場合" do
        it "成功してエリアを作成すること" do
          expect {
            described_class.new.call(valid_params, admin)
          }.to change(Area, :count).by(1)
        end

        it "作成されたエリア情報を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:created)
          expect(result.area.name).to eq("東京")
          expect(result.errors).to be_empty
        end

        it "Presenterでレンダリングできること" do
          result = described_class.new.call(valid_params, admin)
          rendered = Presenters::AreaPresenter.render_area(result.area)

          expect(rendered).to have_key(:id)
          expect(rendered[:name]).to eq("東京")
        end
      end

      context "params[:area][:name]形式の場合" do
        it "成功すること" do
          result = described_class.new.call({ area: { name: "大阪" } }, admin)

          expect(result.success?).to be true
          expect(result.area.name).to eq("大阪")
        end
      end
    end

    describe "異常系" do
      context "バリデーションエラーの場合" do
        it "nameが空の場合、失敗を返すこと" do
          result = described_class.new.call({ name: "" }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
          expect(result.errors).not_to be_empty
        end

        it "nameが33文字の場合、失敗を返すこと" do
          result = described_class.new.call({ name: "a" * 33 }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "エリアが作成されないこと" do
          expect {
            described_class.new.call({ name: "" }, admin)
          }.not_to change(Area, :count)
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(valid_params, current_account) }

        it_behaves_like "admin only service"

        it "エリアが作成されないこと" do
          expect {
            described_class.new.call(valid_params, member)
          }.not_to change(Area, :count)
        end
      end
    end
  end
end
