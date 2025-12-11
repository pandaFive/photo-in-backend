require "rails_helper"

RSpec.describe AssignCycle, type: :model do
  describe "associations" do
    it "taskに属していること" do
      association = AssignCycle.reflect_on_association(:task)
      expect(association.macro).to eq(:belongs_to)
    end

    it "assign_historiesを持っていること" do
      association = AssignCycle.reflect_on_association(:assign_histories)
      expect(association.macro).to eq(:has_many)
    end

    it "commentsを持っていること" do
      association = AssignCycle.reflect_on_association(:comments)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe "#assign" do
    before do
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id)
      @account = create(:account_member)
      @account.add_area(@area)
    end

    it "アサイン可能なアカウントにアサインできること" do
      expect { @cycle.assign }.to change { AssignHistory.count }.by(1)
    end

    it "アサインした履歴を返すこと" do
      result = @cycle.assign

      expect(result).to be_a(AssignHistory)
      expect(result.account_id).to eq(@account.id)
      expect(result.assign_cycle_id).to eq(@cycle.id)
    end

    it "アサイン可能なアカウントがいない場合はfalseを返すこと" do
      # エリアの関連を削除してアサイン可能なアカウントをなくす
      @account.areas.clear

      result = @cycle.assign

      expect(result).to be false
    end
  end

  describe "#get_assignable" do
    before do
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id)
    end

    it "エリアに属するアカウントを取得できること" do
      account = create(:account_member)
      account.add_area(@area)

      assignable = @cycle.get_assignable

      expect(assignable.count).to eq(1)
      expect(assignable.first.id).to eq(account.id)
    end

    it "エリアに属さないアカウントは取得しないこと" do
      other_area = create(:area, name: "Other Area")
      account = create(:account_member)
      account.add_area(other_area)

      assignable = @cycle.get_assignable

      expect(assignable.count).to eq(0)
    end

    it "既にNGがついているアカウントは取得しないこと" do
      account = create(:account_member)
      account.add_area(@area)
      create(:assign_history, account_id: account.id, assign_cycle_id: @cycle.id, ng: true)

      assignable = @cycle.get_assignable

      expect(assignable.count).to eq(0)
    end

    it "キャパシティの4倍以上アサインされているアカウントは取得しないこと" do
      account = create(:account_member, capacity: 1)
      account.add_area(@area)

      # 他のタスクで4つアサインを作成
      4.times do
        other_task = create(:task, area_id: @area.id, task_title: "Other Task #{rand(1000)}")
        other_cycle = create(:assign_cycle, task_id: other_task.id)
        create(:assign_history, account_id: account.id, assign_cycle_id: other_cycle.id, ng: false, completed: false)
      end

      assignable = @cycle.get_assignable

      expect(assignable.count).to eq(0)
    end

    it "複数のアサイン可能なアカウントがいる場合は全て取得すること" do
      account1 = create(:account_member, name: "Account 1")
      account2 = create(:account_member, name: "Account 2")
      account1.add_area(@area)
      account2.add_area(@area)

      assignable = @cycle.get_assignable

      expect(assignable.count).to eq(2)
      expect(assignable.map(&:id)).to include(account1.id, account2.id)
    end
  end

  describe "#deactivation" do
    it "cycleを非アクティブ化できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      cycle = create(:assign_cycle, task_id: task.id, is_active: true)

      cycle.deactivation

      expect(cycle.is_active).to be false
    end
  end

  describe ".unfulfilleds" do
    it "アクティブなcycleを取得できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      active_cycle = create(:assign_cycle, task_id: task.id, is_active: true)
      create(:assign_cycle, task_id: task.id, is_active: false)

      unfulfilleds = AssignCycle.unfulfilleds

      expect(unfulfilleds.count).to eq(1)
      expect(unfulfilleds.first.id).to eq(active_cycle.id)
    end

    it "非アクティブなcycleは取得しないこと" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      create(:assign_cycle, task_id: task.id, is_active: false)

      unfulfilleds = AssignCycle.unfulfilleds

      expect(unfulfilleds.count).to eq(0)
    end
  end
end
