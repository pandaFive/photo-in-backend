require "rails_helper"

RSpec.describe Task, type: :model do
  describe "validations" do
    it "task_titleが存在すれば有効であること" do
      area = create(:area)
      task = Task.new(task_title: "Test Task", area_id: area.id)
      expect(task).to be_valid
    end

    it "task_titleが存在しない場合は無効であること" do
      area = create(:area)
      task = Task.new(task_title: nil, area_id: area.id)
      expect(task).not_to be_valid
    end
  end

  describe "associations" do
    it "areaに属していること" do
      association = Task.reflect_on_association(:area)
      expect(association.macro).to eq(:belongs_to)
    end

    it "tagsを持っていること" do
      association = Task.reflect_on_association(:tags)
      expect(association.macro).to eq(:has_many)
    end

    it "assign_cyclesを持っていること" do
      association = Task.reflect_on_association(:assign_cycles)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe "#add_tag" do
    it "タスクにタグを追加できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      tag = Tag.create(name: "Test Tag")

      expect { task.add_tag(tag) }.to change { task.tags.count }.by(1)
      expect(task.tags).to include(tag)
    end
  end

  describe "#remove_tag" do
    it "タスクからタグを削除できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      tag = Tag.create(name: "Test Tag")
      task.add_tag(tag)

      expect { task.remove_tag(tag) }.to change { task.tags.count }.by(-1)
      expect(task.tags).not_to include(tag)
    end
  end

  describe "#create_new_cycle" do
    it "新しいassign_cycleを作成できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)

      expect { task.create_new_cycle }.to change { AssignCycle.count }.by(1)
    end

    it "既存のcycleを非アクティブ化すること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      old_cycle = create(:assign_cycle, task_id: task.id, is_active: true)

      task.create_new_cycle
      old_cycle.reload

      expect(old_cycle.is_active).to be false
    end

    it "新しいcycleをアクティブにすること" do
      area = create(:area)
      task = create(:task, area_id: area.id)

      new_cycle = task.create_new_cycle

      expect(new_cycle.is_active).to be true
    end
  end

  describe ".get_account_assign_tasks" do
    it "アカウントにアサインされている未完了のタスクを取得できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      account = create(:account_member)
      cycle = create(:assign_cycle, task_id: task.id, is_active: true)
      create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id, ng: false, completed: false)

      tasks = Task.get_account_assign_tasks(account.id)

      expect(tasks.length).to eq(1)
      expect(tasks.first.id).to eq(task.id)
    end

    it "完了したタスクは取得しないこと" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      account = create(:account_member)
      cycle = create(:assign_cycle, task_id: task.id, is_active: true)
      create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id, ng: false, completed: true)

      tasks = Task.get_account_assign_tasks(account.id)

      expect(tasks.length).to eq(0)
    end

    it "NGのタスクは取得しないこと" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      account = create(:account_member)
      cycle = create(:assign_cycle, task_id: task.id, is_active: true)
      create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id, ng: true, completed: false)

      tasks = Task.get_account_assign_tasks(account.id)

      expect(tasks.length).to eq(0)
    end
  end

  describe ".get_active_tasks" do
    it "アクティブなタスクを取得できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      create(:assign_cycle, task_id: task.id, is_active: true)

      tasks = Task.get_active_tasks

      expect(tasks.length).to eq(1)
      expect(tasks.first.id).to eq(task.id)
    end

    it "非アクティブなタスクは取得しないこと" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      create(:assign_cycle, task_id: task.id, is_active: false)

      tasks = Task.get_active_tasks

      expect(tasks.length).to eq(0)
    end
  end

  describe "#current_assignee?" do
    let(:area) { create(:area) }
    let(:task) { create(:task, area_id: area.id) }
    let(:account) { create(:account_member) }
    let(:other_account) { create(:account_member) }

    context "タスクにAssignCycleとAssignHistoryがある場合" do
      let(:cycle) { create(:assign_cycle, task_id: task.id, is_active: true) }

      before do
        create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id)
      end

      it "担当者の場合はtrueを返すこと" do
        expect(task.current_assignee?(account)).to be true
      end

      it "担当者でない場合はfalseを返すこと" do
        expect(task.current_assignee?(other_account)).to be false
      end
    end

    context "複数のAssignCycleがある場合" do
      let(:old_cycle) { create(:assign_cycle, task_id: task.id, is_active: false) }
      let(:new_cycle) { create(:assign_cycle, task_id: task.id, is_active: true) }

      before do
        create(:assign_history, account_id: other_account.id, assign_cycle_id: old_cycle.id)
        create(:assign_history, account_id: account.id, assign_cycle_id: new_cycle.id)
      end

      it "最新のサイクルの担当者の場合はtrueを返すこと" do
        expect(task.current_assignee?(account)).to be true
      end

      it "古いサイクルの担当者の場合はfalseを返すこと" do
        expect(task.current_assignee?(other_account)).to be false
      end
    end

    context "同一サイクルで複数のAssignHistoryがある場合" do
      let(:cycle) { create(:assign_cycle, task_id: task.id, is_active: true) }

      before do
        # 古い履歴（NG済み）
        create(:assign_history, account_id: other_account.id, assign_cycle_id: cycle.id, ng: true)
        # 新しい履歴（現在の担当者）
        create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id)
      end

      it "最新の履歴の担当者の場合はtrueを返すこと" do
        expect(task.current_assignee?(account)).to be true
      end

      it "過去の履歴の担当者の場合はfalseを返すこと" do
        expect(task.current_assignee?(other_account)).to be false
      end
    end

    context "AssignCycleがない場合" do
      it "falseを返すこと" do
        expect(task.current_assignee?(account)).to be false
      end
    end

    context "AssignHistoryがない場合" do
      before do
        create(:assign_cycle, task_id: task.id, is_active: true)
      end

      it "falseを返すこと" do
        expect(task.current_assignee?(account)).to be false
      end
    end

    context "タスクが完了済みの場合" do
      let(:cycle) { create(:assign_cycle, task_id: task.id, is_active: false) }

      before do
        create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id, completed: true)
      end

      it "falseを返すこと（完了済みタスクは編集不可）" do
        expect(task.current_assignee?(account)).to be false
      end
    end

    context "履歴がNG済みの場合" do
      let(:cycle) { create(:assign_cycle, task_id: task.id, is_active: true) }

      before do
        create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id, ng: true)
      end

      it "falseを返すこと（NG済みは担当者ではない）" do
        expect(task.current_assignee?(account)).to be false
      end
    end
  end
end
