# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::Show, type: :service do
  let(:admin_account) { create(:account) }
  let(:member_account) { create(:account_member) }
  let!(:area) { create(:area, name: "テストエリア") }
  let!(:task) { create(:task, area:, task_title: "テストタスク") }

  describe "#call" do
    describe "正常系" do
      context "存在するタスクを取得する場合" do
        let(:params) { { id: task.id.to_s } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
        end

        it "taskに該当タスクを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.task).to eq(task)
        end

        it "statusが:okであること" do
          result = described_class.new.call(params, admin_account)
          expect(result.status).to eq(:ok)
        end

        it "errorsが空であること" do
          result = described_class.new.call(params, admin_account)
          expect(result.errors).to be_empty
        end
      end

      context "memberアカウントでも取得可能" do
        let(:params) { { id: task.id.to_s } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, member_account)
          expect(result.success?).to be true
        end

        it "taskを返すこと" do
          result = described_class.new.call(params, member_account)
          expect(result.task).to eq(task)
        end
      end

      context "idが整数の場合" do
        let(:params) { { id: task.id } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
        end
      end
    end

    describe "異常系" do
      context "認証エラー" do
        context "current_accountがnilの場合" do
          let(:params) { { id: task.id.to_s } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, nil)
            expect(result.success?).to be false
          end

          it "statusが:unauthorizedであること" do
            result = described_class.new.call(params, nil)
            expect(result.status).to eq(:unauthorized)
          end

          it "認証エラーメッセージを返すこと" do
            result = described_class.new.call(params, nil)
            expect(result.errors).to include("認証が必要です")
          end
        end
      end

      context "バリデーションエラー" do
        context "idが空の場合" do
          let(:params) { { id: "" } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, admin_account)
            expect(result.success?).to be false
          end

          it "statusが:unprocessable_entityであること" do
            result = described_class.new.call(params, admin_account)
            expect(result.status).to eq(:unprocessable_entity)
          end

          it "バリデーションエラーメッセージを返すこと" do
            result = described_class.new.call(params, admin_account)
            expect(result.errors).to include("Id can't be blank")
          end
        end

        context "idが非数値の場合" do
          let(:params) { { id: "abc" } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params, admin_account)
            expect(result.success?).to be false
          end

          it "statusが:unprocessable_entityであること" do
            result = described_class.new.call(params, admin_account)
            expect(result.status).to eq(:unprocessable_entity)
          end

          it "バリデーションエラーメッセージを返すこと" do
            result = described_class.new.call(params, admin_account)
            expect(result.errors).to include("Id is not a number")
          end
        end
      end

      context "タスクが存在しない場合" do
        let(:params) { { id: "999999" } }

        it "success?がfalseを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be false
        end

        it "statusが:not_foundであること" do
          result = described_class.new.call(params, admin_account)
          expect(result.status).to eq(:not_found)
        end

        it "エラーメッセージを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.errors).to include("タスクが見つかりません")
        end
      end
    end

    describe "依存性注入" do
      context "カスタムリポジトリを使用する場合" do
        let(:mock_repository) { instance_double(Services::Tasks::Repository) }
        let(:service) { described_class.new(repository: mock_repository) }
        let(:params) { { id: "1" } }

        it "指定されたリポジトリのfind_by_idを呼び出すこと" do
          allow(mock_repository).to receive(:find_by_id).with(1).and_return(task)
          service.call(params, admin_account)
          expect(mock_repository).to have_received(:find_by_id).with(1)
        end

        it "リポジトリがnilを返した場合はnot_foundを返すこと" do
          allow(mock_repository).to receive(:find_by_id).with(1).and_return(nil)
          result = service.call(params, admin_account)
          expect(result.success?).to be false
          expect(result.status).to eq(:not_found)
        end
      end
    end
  end
end
