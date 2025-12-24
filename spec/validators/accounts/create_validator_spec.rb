# frozen_string_literal: true

require "rails_helper"

RSpec.describe Validators::Accounts::Create do
  let(:contract) { Contracts::Accounts::Create.new(area:) }

  describe "#validate" do
    context "areaが配列の場合" do
      let(:area) { [1, 2, 3] }

      it "エラーがないこと" do
        contract.valid?
        expect(contract.errors[:area]).to be_empty
      end
    end

    context "areaが配列でない場合" do
      let(:area) { "not_array" }

      it "エラーを追加すること" do
        contract.valid?
        expect(contract.errors[:area]).to include("must be an array")
      end
    end

    context "areaに数値以外が含まれる場合" do
      let(:area) { [1, "abc", 3] }

      it "エラーを追加すること" do
        contract.valid?
        expect(contract.errors[:area]).to include("must contain only numeric ids")
      end
    end
  end
end
