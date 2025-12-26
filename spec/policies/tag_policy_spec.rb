# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::TagPolicy, type: :policy do
  describe "#admin_only?" do
    context "admin アカウントの場合" do
      let(:account) { build(:account, role: "admin") }
      let(:policy) { described_class.new(account) }

      it "true を返すこと" do
        expect(policy.admin_only?).to be true
      end
    end

    context "member アカウントの場合" do
      let(:account) { build(:account, role: "member") }
      let(:policy) { described_class.new(account) }

      it "false を返すこと" do
        expect(policy.admin_only?).to be false
      end
    end

    context "nil アカウントの場合" do
      let(:policy) { described_class.new(nil) }

      it "false を返すこと" do
        expect(policy.admin_only?).to be false
      end
    end

    context "role が nil の場合" do
      let(:account) { build(:account, role: nil) }
      let(:policy) { described_class.new(account) }

      it "false を返すこと" do
        expect(policy.admin_only?).to be false
      end
    end
  end
end
