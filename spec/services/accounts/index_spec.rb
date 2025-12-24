# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Accounts::Index, type: :service do
  describe "#call" do
    let(:admin) { create(:account, role: "admin") }
    let(:member) { create(:account_member, name: "member_for_auth") }

    describe "正常系" do
      let(:member1) { create(:account_member, name: "member1") }
      let(:member2) { create(:account_member, name: "member2") }
      let(:area) { create(:area, name: "Tokyo") }
      let(:task) { create(:task, area_id: area.id) }
      let(:cycle) { create(:assign_cycle, task_id: task.id) }

      before do
        member1.add_area(area)
        member2.add_area(area)

        # legacy集計と同じ条件でAssignHistoryを作成
        create(:assign_history, account_id: member1.id, assign_cycle_id: cycle.id, completed: true, completed_at: Time.zone.now)
        create(:assign_history, account_id: member2.id, assign_cycle_id: cycle.id, ng: true)
      end

      it "memberロールのアカウントのみを返すこと" do
        result = described_class.new.call(admin)

        expect(result.accounts.all? { |a| a.role == "member" }).to be true
        expect(result.accounts).not_to include(admin)
      end

      it "各アカウントの統計情報が正しいこと" do
        result = described_class.new.call(admin)
        rendered = Presenters::AccountPresenter.render_accounts(result.accounts, result.data)

        member1_data = rendered.find { |r| r[:id] == member1.id }
        expect(member1_data[:total]).to eq(1)
        expect(member1_data[:assign]).to eq(0)

        # member2はng=trueのみ、completed=falseなのでtotal=0、ng_rate=0.0
        member2_data = rendered.find { |r| r[:id] == member2.id }
        expect(member2_data[:total]).to eq(0)
        expect(member2_data[:ng_rate]).to eq(0.0)
      end
    end

    describe "異常系" do
      describe "権限エラーの場合" do
        let(:current_account) { member }
        let(:result) { described_class.new.call(current_account) }

        it_behaves_like "admin only service"

        it "accountsが空配列であること" do
          expect(result.accounts).to be_empty
        end
      end
    end

    describe "エッジケース" do
      context "メンバーが存在しない場合" do
        it "空の配列を返すこと" do
          # adminのみ存在
          result = described_class.new.call(admin)

          expect(result.success?).to be true
          expect(result.accounts).to be_empty
        end
      end

      context "AssignHistoryが存在しない場合" do
        let!(:member_no_history) { create(:account_member, name: "no_history") }

        it "統計値がすべて0で返されること" do
          result = described_class.new.call(admin)
          rendered = Presenters::AccountPresenter.render_accounts(result.accounts, result.data)

          member_data = rendered.find { |r| r[:id] == member_no_history.id }
          expect(member_data[:total]).to eq(0)
          expect(member_data[:week]).to eq(0)
          expect(member_data[:ng_rate]).to eq(0.0)
          expect(member_data[:assign]).to eq(0)
        end
      end
    end
  end
end
