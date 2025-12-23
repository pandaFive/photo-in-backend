require "rails_helper"

RSpec.describe Services::Tasks::Index, type: :service do
  let(:admin_account) { create(:account) }
  let(:member_account) { create(:account_member) }
  let!(:area) { create(:area, name: "テストエリア") }

  describe "#call" do
    describe "正常系" do
      let!(:task) { create(:task, area: area) }
      let!(:cycle) { create(:assign_cycle, task: task, is_active: true) }

      context "type='all'を指定した場合" do
        let(:params) { { type: "all" } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
        end

        it "tasksにアクティブタスク一覧を返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.tasks).to be_present
          expect(result.tasks.length).to be >= 1
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

      context "type='ng'を指定した場合" do
        let!(:ng_member) { create(:account_member, areas: [area]) }
        let!(:history) { create(:assign_history, assign_cycle: cycle, account: ng_member, ng: true) }

        let(:params) { { type: "ng" } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.success?).to be true
        end

        it "NGタスク一覧を返すこと" do
          result = described_class.new.call(params, admin_account)
          expect(result.tasks).to be_present
        end

        it "statusが:okであること" do
          result = described_class.new.call(params, admin_account)
          expect(result.status).to eq(:ok)
        end
      end

      context "memberアカウントの場合も取得可能" do
        let(:params) { { type: "all" } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params, member_account)
          expect(result.success?).to be true
        end
      end
    end

    describe "異常系" do
      context "認証エラー" do
        context "current_accountがnilの場合" do
          let(:params) { { type: "all" } }

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
        context "typeが空の場合" do
          let(:params) { { type: "" } }

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
            expect(result.errors).to include("Type can't be blank")
          end
        end

        context "typeが無効な値の場合" do
          let(:params) { { type: "invalid" } }

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
            expect(result.errors).to include("Type is not included in the list")
          end
        end
      end
    end

    describe "タスクが存在しない場合" do
      let(:params) { { type: "all" } }

      it "success?がtrueを返すこと" do
        result = described_class.new.call(params, admin_account)
        expect(result.success?).to be true
      end

      it "空の配列を返すこと" do
        result = described_class.new.call(params, admin_account)
        expect(result.tasks).to be_empty
      end
    end
  end
end
