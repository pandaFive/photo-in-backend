require "rails_helper"

RSpec.describe Contracts::Authentications::Login do
  describe ".call" do
    context "有効なパラメータの場合" do
      let(:params) { { name: "testuser", password: "password123" } }

      it "success?がtrueを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be true
      end

      it "valueにcontractオブジェクトを返すこと" do
        result = described_class.call(params)
        expect(result.value).to be_a(described_class)
        expect(result.value.name).to eq("testuser")
        expect(result.value.password).to eq("password123")
      end

      it "errorsが空であること" do
        result = described_class.call(params)
        expect(result.errors).to be_empty
      end
    end

    context "nameが空の場合" do
      let(:params) { { name: "", password: "password123" } }

      it "success?がfalseを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be false
      end

      it "エラーメッセージを返すこと" do
        result = described_class.call(params)
        expect(result.errors).to include("Name can't be blank")
      end
    end

    context "nameがnilの場合" do
      let(:params) { { name: nil, password: "password123" } }

      it "success?がfalseを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be false
      end

      it "エラーメッセージを返すこと" do
        result = described_class.call(params)
        expect(result.errors).to include("Name can't be blank")
      end
    end

    context "passwordが空の場合" do
      let(:params) { { name: "testuser", password: "" } }

      it "success?がfalseを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be false
      end

      it "エラーメッセージを返すこと" do
        result = described_class.call(params)
        expect(result.errors).to include("Password can't be blank")
      end
    end

    context "passwordがnilの場合" do
      let(:params) { { name: "testuser", password: nil } }

      it "success?がfalseを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be false
      end

      it "エラーメッセージを返すこと" do
        result = described_class.call(params)
        expect(result.errors).to include("Password can't be blank")
      end
    end

    context "両方のパラメータが空の場合" do
      let(:params) { { name: "", password: "" } }

      it "success?がfalseを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be false
      end

      it "両方のエラーメッセージを返すこと" do
        result = described_class.call(params)
        expect(result.errors).to include("Name can't be blank")
        expect(result.errors).to include("Password can't be blank")
      end
    end

    context "パラメータが指定されていない場合" do
      let(:params) { {} }

      it "success?がfalseを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be false
      end

      it "両方のエラーメッセージを返すこと" do
        result = described_class.call(params)
        expect(result.errors).to include("Name can't be blank")
        expect(result.errors).to include("Password can't be blank")
      end
    end

    context "passwordが72文字の場合" do
      let(:params) { { name: "testuser", password: "a" * 72 } }

      it "success?がtrueを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be true
      end
    end

    context "passwordが73文字以上の場合" do
      let(:params) { { name: "testuser", password: "a" * 73 } }

      it "success?がfalseを返すこと" do
        result = described_class.call(params)
        expect(result.success?).to be false
      end

      it "エラーメッセージを返すこと" do
        result = described_class.call(params)
        expect(result.errors).to include("Password is too long (maximum is 72 characters)")
      end
    end
  end
end
