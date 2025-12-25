# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Areas::Show, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:area) { create(:area, name: "東京") }

    describe "正常系" do
      context "adminユーザーの場合" do
        it "成功を返すこと" do
          result = described_class.new.call({ id: area.id }, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.errors).to be_empty
        end

        it "指定したエリアを返すこと" do
          result = described_class.new.call({ id: area.id }, admin)

          expect(result.area.id).to eq(area.id)
          expect(result.area.name).to eq("東京")
        end

        it "Presenterでレンダリングできること" do
          result = described_class.new.call({ id: area.id }, admin)
          rendered = Presenters::AreaPresenter.render_area(result.area)

          expect(rendered).to eq({ id: area.id, name: "東京" })
        end
      end

      context "memberユーザーの場合" do
        it "成功を返すこと" do
          result = described_class.new.call({ id: area.id }, member)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
        end
      end
    end

    describe "異常系" do
      context "current_accountがnilの場合" do
        it "unauthorizedを返すこと" do
          result = described_class.new.call({ id: area.id }, nil)

          expect(result.success?).to be false
          expect(result.status).to eq(:unauthorized)
          expect(result.errors).to include("認証が必要です")
        end
      end

      context "バリデーションエラーの場合" do
        it "idが無効な場合、unprocessable_entityを返すこと" do
          result = described_class.new.call({ id: "abc" }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:unprocessable_entity)
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
    end
  end
end
