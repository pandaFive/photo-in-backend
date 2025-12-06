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
      tag = Tag.create(tag_name: "Test Tag")

      expect { task.add_tag(tag) }.to change { task.tags.count }.by(1)
      expect(task.tags).to include(tag)
    end
  end

  describe "#remove_tag" do
    it "タスクからタグを削除できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      tag = Tag.create(tag_name: "Test Tag")
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

  describe ".getAccountAssignTasks" do
    it "アカウントにアサインされている未完了のタスクを取得できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      account = create(:account_member)
      cycle = create(:assign_cycle, task_id: task.id, is_active: true)
      history = create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id, ng: false, completed: false)

      tasks = Task.getAccountAssignTasks(account.id)

      expect(tasks.count).to eq(1)
      expect(tasks.first.id).to eq(task.id)
    end

    it "完了したタスクは取得しないこと" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      account = create(:account_member)
      cycle = create(:assign_cycle, task_id: task.id, is_active: true)
      history = create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id, ng: false, completed: true)

      tasks = Task.getAccountAssignTasks(account.id)

      expect(tasks.count).to eq(0)
    end

    it "NGのタスクは取得しないこと" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      account = create(:account_member)
      cycle = create(:assign_cycle, task_id: task.id, is_active: true)
      history = create(:assign_history, account_id: account.id, assign_cycle_id: cycle.id, ng: true, completed: false)

      tasks = Task.getAccountAssignTasks(account.id)

      expect(tasks.count).to eq(0)
    end
  end

  describe ".getActiveTasks" do
    it "アクティブなタスクを取得できること" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      cycle = create(:assign_cycle, task_id: task.id, is_active: true)

      tasks = Task.getActiveTasks

      expect(tasks.count).to eq(1)
      expect(tasks.first.id).to eq(task.id)
    end

    it "非アクティブなタスクは取得しないこと" do
      area = create(:area)
      task = create(:task, area_id: area.id)
      cycle = create(:assign_cycle, task_id: task.id, is_active: false)

      tasks = Task.getActiveTasks

      expect(tasks.count).to eq(0)
    end
  end

  describe ".getAreaId" do
    it "タイトルに含まれるエリア名からエリアIDを取得できること" do
      area = create(:area, name: "テストエリア")

      area_id = Task.getAreaId("テストエリアのタスク")

      expect(area_id).to eq(area.id)
    end

    it "エリア名が含まれていない場合はnilを返すこと" do
      area_id = Task.getAreaId("存在しないエリアのタスク")

      expect(area_id).to be_nil
    end
  end
end
