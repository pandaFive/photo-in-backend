# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::Accounts::Update, type: :contract do
  describe ".call" do
    context "正常系" do
      it "idのみで成功すること" do
        result = described_class.call({ id: 1 })

        expect(result.success?).to be true
        expect(result.value[:id]).to eq(1)
      end

      it "名前を更新できること" do
        result = described_class.call({ id: 1, name: "NewName" })

        expect(result.success?).to be true
        expect(result.value[:name]).to eq("NewName")
      end

      it "パスワードを更新できること" do
        result = described_class.call({ id: 1, password: "newpassword123" })

        expect(result.success?).to be true
        expect(result.value[:password]).to eq("newpassword123")
      end

      it "ロールを更新できること" do
        result = described_class.call({ id: 1, role: "admin" })

        expect(result.success?).to be true
        expect(result.value[:role]).to eq("admin")
      end

      it "キャパシティを更新できること" do
        result = described_class.call({ id: 1, capacity: 5 })

        expect(result.success?).to be true
        expect(result.value[:capacity]).to eq(5)
      end

      it "キャパシティ0を設定できること" do
        result = described_class.call({ id: 1, capacity: 0 })

        expect(result.success?).to be true
        expect(result.value[:capacity]).to eq(0)
      end

      it "複数フィールドを同時に更新できること" do
        result = described_class.call({
          id: 1,
          name: "NewName",
          role: "member",
          capacity: 3
        })

        expect(result.success?).to be true
        expect(result.value[:name]).to eq("NewName")
        expect(result.value[:role]).to eq("member")
        expect(result.value[:capacity]).to eq(3)
      end
    end

    context "異常系 - ID検証" do
      it "idがnilの場合、失敗すること" do
        result = described_class.call({ id: nil, name: "Test" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "idが0の場合、失敗すること" do
        result = described_class.call({ id: 0, name: "Test" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "idが負数の場合、失敗すること" do
        result = described_class.call({ id: -1, name: "Test" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "idが数値でない場合、失敗すること" do
        result = described_class.call({ id: "abc", name: "Test" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end
    end

    context "異常系 - 名前検証" do
      it "名前が33文字以上の場合、失敗すること" do
        result = described_class.call({ id: 1, name: "a" * 33 })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "名前が32文字の場合、成功すること" do
        result = described_class.call({ id: 1, name: "a" * 32 })

        expect(result.success?).to be true
      end
    end

    context "異常系 - パスワード検証" do
      it "パスワードが7文字以下の場合、失敗すること" do
        result = described_class.call({ id: 1, password: "short" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "パスワードが8文字の場合、成功すること" do
        result = described_class.call({ id: 1, password: "password" })

        expect(result.success?).to be true
      end
    end

    context "異常系 - ロール検証" do
      it "無効なロールの場合、失敗すること" do
        result = described_class.call({ id: 1, role: "superuser" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "adminロールは有効であること" do
        result = described_class.call({ id: 1, role: "admin" })

        expect(result.success?).to be true
      end

      it "memberロールは有効であること" do
        result = described_class.call({ id: 1, role: "member" })

        expect(result.success?).to be true
      end
    end

    context "異常系 - キャパシティ検証" do
      it "キャパシティが負数の場合、失敗すること" do
        result = described_class.call({ id: 1, capacity: -1 })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end
    end
  end
end
