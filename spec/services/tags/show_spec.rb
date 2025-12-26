# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tags::Show, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }
    let!(:tag) { create(:tag, name: "緊急") }

    describe "正常系" do
      context "adminユーザーの場合" do
        it "成功を返すこと" do
          result = described_class.new.call({ id: tag.id }, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
          expect(result.errors).to be_empty
        end

        it "指定したタグを返すこと" do
          result = described_class.new.call({ id: tag.id }, admin)

          expect(result.tag.id).to eq(tag.id)
          expect(result.tag.name).to eq("緊急")
        end

        it "Presenterでレンダリングできること" do
          result = described_class.new.call({ id: tag.id }, admin)
          rendered = Presenters::TagPresenter.render_tag(result.tag)

          expect(rendered).to eq({ id: tag.id, name: "緊急" })
        end
      end

      context "memberユーザーの場合" do
        it "成功を返すこと" do
          result = described_class.new.call({ id: tag.id }, member)

          expect(result.success?).to be true
          expect(result.status).to eq(:ok)
        end
      end
    end

    describe "異常系" do
      context "current_accountがnilの場合" do
        it "unauthorizedを返すこと" do
          result = described_class.new.call({ id: tag.id }, nil)

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

      context "タグが存在しない場合" do
        it "not_foundを返すこと" do
          result = described_class.new.call({ id: 999999 }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
          expect(result.errors.first).to include("999999")
        end
      end

      context "データベースエラーが発生した場合" do
        let(:mock_repository) { instance_double(Services::Tags::Repository) }

        before do
          allow(mock_repository).to receive(:find_by_id).and_raise(ActiveRecord::StatementInvalid.new("Database error"))
        end

        it "internal_server_errorを返すこと" do
          result = described_class.new(repository: mock_repository).call({ id: 1 }, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:internal_server_error)
          expect(result.errors).to include("データベースエラーが発生しました")
        end
      end
    end
  end
end
