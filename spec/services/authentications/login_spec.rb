require "rails_helper"

RSpec.describe Services::Authentications::Login, type: :service do
  describe "#call" do
    let!(:account) { create(:account_member, name: "testuser", password: "password123") }

    describe "正常系" do
      context "正しい認証情報でログインする場合" do
        let(:params) { { name: "testuser", password: "password123" } }

        it "success?がtrueを返すこと" do
          result = described_class.new.call(params)
          expect(result.success?).to be true
        end

        it "accountオブジェクトを返すこと" do
          result = described_class.new.call(params)
          expect(result.account).to eq(account)
        end

        it "statusが:okであること" do
          result = described_class.new.call(params)
          expect(result.status).to eq(:ok)
        end

        it "errorsが空であること" do
          result = described_class.new.call(params)
          expect(result.errors).to be_empty
        end
      end
    end

    describe "異常系" do
      context "存在しないユーザー名でログインする場合" do
        let(:params) { { name: "nonexistent", password: "password123" } }

        it "success?がfalseを返すこと" do
          result = described_class.new.call(params)
          expect(result.success?).to be false
        end

        it "accountがnilであること" do
          result = described_class.new.call(params)
          expect(result.account).to be_nil
        end

        it "statusが:unprocessable_entityであること" do
          result = described_class.new.call(params)
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "エラーメッセージを返すこと" do
          result = described_class.new.call(params)
          expect(result.errors).to include("認証に失敗しました")
        end
      end

      context "間違ったパスワードでログインする場合" do
        let(:params) { { name: "testuser", password: "wrongpassword" } }

        it "success?がfalseを返すこと" do
          result = described_class.new.call(params)
          expect(result.success?).to be false
        end

        it "accountがnilであること" do
          result = described_class.new.call(params)
          expect(result.account).to be_nil
        end

        it "statusが:unprocessable_entityであること" do
          result = described_class.new.call(params)
          expect(result.status).to eq(:unprocessable_entity)
        end

        it "エラーメッセージを返すこと" do
          result = described_class.new.call(params)
          expect(result.errors).to include("認証に失敗しました")
        end
      end

      context "バリデーションエラーの場合" do
        context "nameが空の場合" do
          let(:params) { { name: "", password: "password123" } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params)
            expect(result.success?).to be false
          end

          it "statusが:unprocessable_entityであること" do
            result = described_class.new.call(params)
            expect(result.status).to eq(:unprocessable_entity)
          end

          it "バリデーションエラーメッセージを返すこと" do
            result = described_class.new.call(params)
            expect(result.errors).to include("Name can't be blank")
          end
        end

        context "passwordが空の場合" do
          let(:params) { { name: "testuser", password: "" } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params)
            expect(result.success?).to be false
          end

          it "statusが:unprocessable_entityであること" do
            result = described_class.new.call(params)
            expect(result.status).to eq(:unprocessable_entity)
          end

          it "バリデーションエラーメッセージを返すこと" do
            result = described_class.new.call(params)
            expect(result.errors).to include("Password can't be blank")
          end
        end

        context "両方のパラメータが空の場合" do
          let(:params) { { name: "", password: "" } }

          it "success?がfalseを返すこと" do
            result = described_class.new.call(params)
            expect(result.success?).to be false
          end

          it "複数のエラーメッセージを返すこと" do
            result = described_class.new.call(params)
            expect(result.errors).to include("Name can't be blank")
            expect(result.errors).to include("Password can't be blank")
          end
        end
      end
    end

    describe "セキュリティ" do
      context "タイミング攻撃対策" do
        it "存在しないユーザーでもbcrypt処理が実行されること" do
          # BCrypt::Passwordが呼ばれることを確認
          expect(BCrypt::Password).to receive(:new).and_call_original

          described_class.new.call({ name: "nonexistent", password: "password123" })
        end

        it "存在しないユーザーと存在するユーザーで同じエラーメッセージを返すこと" do
          result_nonexistent = described_class.new.call({ name: "nonexistent", password: "password123" })
          result_wrong_password = described_class.new.call({ name: "testuser", password: "wrongpassword" })

          expect(result_nonexistent.errors).to eq(result_wrong_password.errors)
        end
      end
    end

    describe "Presenterとの連携" do
      context "成功時" do
        let(:params) { { name: "testuser", password: "password123" } }

        it "Presenterでレンダリングできること" do
          result = described_class.new.call(params)
          rendered = Presenters::AccountPresenter.render_auth(result.account)

          expect(rendered).to have_key(:account)
          expect(rendered[:account]).to include(
            id: account.id,
            name: "testuser"
          )
          expect(rendered[:account]).to have_key(:token)
        end
      end
    end
  end
end
