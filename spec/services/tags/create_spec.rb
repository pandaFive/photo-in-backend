# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tags::Create, type: :service do
  describe "#call" do
    let!(:admin) { create(:account, role: "admin") }
    let!(:member) { create(:account_member) }

    let(:valid_params) { { name: "緊急" } }

    describe "正常系" do
      context "adminユーザーが有効なパラメータでタグを作成する場合" do
        it "成功してタグを作成すること" do
          expect {
            described_class.new.call(valid_params, admin)
          }.to change(Tag, :count).by(1)
        end

        it "作成されたタグ情報を返すこと" do
          result = described_class.new.call(valid_params, admin)

          expect(result.success?).to be true
          expect(result.status).to eq(:created)
          expect(result.tag.name).to eq("緊急")
          expect(result.errors).to be_empty
        end

        it "Presenterでレンダリングできること" do
          result = described_class.new.call(valid_params, admin)
          rendered = Presenters::TagPresenter.render_tag(result.tag)

          expect(rendered).to have_key(:id)
          expect(rendered[:name]).to eq("緊急")
        end
      end

      context "params[:tag][:name]形式の場合" do
        it "成功すること" do
          result = described_class.new.call({ tag: { name: "重要" } }, admin)

          expect(result.success?).to be true
          expect(result.tag.name).to eq("重要")
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

        it "タグが作成されないこと" do
          expect {
            described_class.new.call({ name: "" }, admin)
          }.not_to change(Tag, :count)
        end
      end

      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(valid_params, current_account) }

        it_behaves_like "admin only service"

        it "タグが作成されないこと" do
          expect {
            described_class.new.call(valid_params, member)
          }.not_to change(Tag, :count)
        end
      end

      context "一意性制約違反の場合" do
        let(:mock_repository) { instance_double(Services::Tags::Repository) }

        before do
          allow(mock_repository).to receive(:build).and_return(Tag.new(name: "緊急"))
          allow(mock_repository).to receive(:save).and_raise(ActiveRecord::RecordNotUnique.new("Duplicate entry"))
        end

        it "conflictを返すこと" do
          result = described_class.new(repository: mock_repository).call(valid_params, admin)

          expect(result.success?).to be false
          expect(result.status).to eq(:conflict)
          expect(result.errors).to include("このタグは既に存在します")
        end
      end

      context "データベースエラーが発生した場合" do
        let(:mock_repository) { instance_double(Services::Tags::Repository) }

        before do
          allow(mock_repository).to receive(:build).and_return(Tag.new(name: "緊急"))
          allow(mock_repository).to receive(:save).and_raise(ActiveRecord::StatementInvalid.new("Database error"))
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
