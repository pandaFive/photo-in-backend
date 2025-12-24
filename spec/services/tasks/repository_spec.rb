# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Tasks::Repository, type: :service do
  let(:repository) { described_class.new }
  let!(:area) { create(:area) }

  describe "#find_by_id" do
    let!(:task) { create(:task, area:) }

    context "存在するIDの場合" do
      it "タスクを返すこと" do
        result = repository.find_by_id(task.id)
        expect(result).to eq(task)
      end
    end

    context "存在しないIDの場合" do
      it "nilを返すこと" do
        result = repository.find_by_id(999999)
        expect(result).to be_nil
      end
    end
  end

  describe "#find_by_id_with_lock" do
    let!(:task) { create(:task, area:) }

    context "存在するIDの場合" do
      it "タスクを返すこと" do
        result = repository.find_by_id_with_lock(task.id)
        expect(result).to eq(task)
      end
    end

    context "存在しないIDの場合" do
      it "nilを返すこと" do
        result = repository.find_by_id_with_lock(999999)
        expect(result).to be_nil
      end
    end
  end

  describe "#build" do
    it "新しいTaskインスタンスを返すこと" do
      attrs = { task_title: "テストタスク", area_id: area.id }
      result = repository.build(attrs)

      expect(result).to be_a(Task)
      expect(result).to be_new_record
      expect(result.task_title).to eq("テストタスク")
    end
  end

  describe "#save" do
    context "有効なタスクの場合" do
      it "trueを返すこと" do
        task = Task.new(task_title: "テストタスク", area_id: area.id)
        result = repository.save(task)

        expect(result).to be true
        expect(task).to be_persisted
      end
    end

    context "無効なタスクの場合" do
      it "falseを返すこと" do
        task = Task.new(task_title: nil, area_id: area.id)
        result = repository.save(task)

        expect(result).to be false
      end
    end
  end

  describe "#update" do
    let!(:task) { create(:task, task_title: "元のタイトル", area:) }

    context "有効な属性の場合" do
      it "trueを返すこと" do
        result = repository.update(task, { task_title: "新しいタイトル" })

        expect(result).to be true
        expect(task.reload.task_title).to eq("新しいタイトル")
      end
    end

    context "無効な属性の場合" do
      it "falseを返すこと" do
        result = repository.update(task, { task_title: nil })

        expect(result).to be false
      end
    end
  end

  describe "#delete" do
    let!(:task) { create(:task, area:) }

    context "削除可能なタスクの場合" do
      it "削除されたタスクを返すこと（truthy）" do
        result = repository.delete(task)

        expect(result).to be_truthy
        expect(result).to be_frozen
      end

      it "タスクがDBから削除されること" do
        expect {
          repository.delete(task)
        }.to change(Task, :count).by(-1)
      end
    end

    context "関連データがある場合" do
      let!(:assign_cycle) { create(:assign_cycle, task:) }

      it "ActiveRecord::InvalidForeignKeyを発生させること" do
        expect {
          repository.delete(task)
        }.to raise_error(ActiveRecord::InvalidForeignKey)
      end

      it "タスクが削除されないこと" do
        expect {
          repository.delete(task) rescue nil
        }.not_to change(Task, :count)
      end
    end
  end

  describe "#infer_area_id" do
    it "Area.get_area_idを呼び出すこと" do
      allow(Area).to receive(:get_area_id).with("テスト").and_return(area.id)

      result = repository.infer_area_id("テスト")

      expect(result).to eq(area.id)
      expect(Area).to have_received(:get_area_id).with("テスト")
    end
  end

  describe "#default_area_id" do
    it "最初のエリアのIDを返すこと" do
      result = repository.default_area_id

      expect(result).to eq(Area.first.id)
    end

    context "エリアが存在しない場合" do
      before { Area.destroy_all }

      it "nilを返すこと" do
        result = repository.default_area_id

        expect(result).to be_nil
      end
    end
  end

  describe "#list_active_tasks" do
    it "Task.get_active_tasksを呼び出すこと" do
      allow(Task).to receive(:get_active_tasks).and_return([])

      repository.list_active_tasks

      expect(Task).to have_received(:get_active_tasks)
    end
  end

  describe "#list_ng_tasks" do
    it "Task.get_ng_tasksを呼び出すこと" do
      allow(Task).to receive(:get_ng_tasks).and_return([])

      repository.list_ng_tasks

      expect(Task).to have_received(:get_ng_tasks)
    end
  end
end
