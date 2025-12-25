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

  describe "#find_tag" do
    let!(:tag) { create(:tag) }

    context "存在するIDの場合" do
      it "タグを返すこと" do
        result = repository.find_tag(tag.id)
        expect(result).to eq(tag)
      end
    end

    context "存在しないIDの場合" do
      it "nilを返すこと" do
        result = repository.find_tag(999999)
        expect(result).to be_nil
      end
    end
  end

  describe "#add_tag" do
    let!(:task) { create(:task, area:) }
    let!(:tag) { create(:tag) }

    context "タグが未追加の場合" do
      it "trueを返すこと" do
        result = repository.add_tag(task, tag)
        expect(result).to be true
      end

      it "タスクにタグが追加されること" do
        repository.add_tag(task, tag)
        expect(task.tags).to include(tag)
      end

      it "TagTaskレコードが作成されること" do
        expect {
          repository.add_tag(task, tag)
        }.to change(TagTask, :count).by(1)
      end
    end

    context "タグが既に追加されている場合" do
      before { task.tags << tag }

      it "falseを返すこと" do
        result = repository.add_tag(task, tag)
        expect(result).to be false
      end

      it "TagTaskレコードが増えないこと" do
        expect {
          repository.add_tag(task, tag)
        }.not_to change(TagTask, :count)
      end
    end
  end

  describe "#remove_tag" do
    let!(:task) { create(:task, area:) }
    let!(:tag) { create(:tag) }

    context "タグが追加されている場合" do
      before { task.tags << tag }

      it "trueを返すこと" do
        result = repository.remove_tag(task, tag)
        expect(result).to be true
      end

      it "タスクからタグが削除されること" do
        repository.remove_tag(task, tag)
        expect(task.tags).not_to include(tag)
      end

      it "TagTaskレコードが削除されること" do
        expect {
          repository.remove_tag(task, tag)
        }.to change(TagTask, :count).by(-1)
      end
    end

    context "タグが追加されていない場合" do
      it "falseを返すこと" do
        result = repository.remove_tag(task, tag)
        expect(result).to be false
      end

      it "TagTaskレコードが変わらないこと" do
        expect {
          repository.remove_tag(task, tag)
        }.not_to change(TagTask, :count)
      end
    end
  end

  describe "#find_assign_history_with_lock" do
    let!(:task) { create(:task, area:) }
    let!(:account) { create(:account) }
    let!(:assign_cycle) { create(:assign_cycle, task:) }
    let!(:assign_history) { create(:assign_history, assign_cycle:, account:) }

    context "存在するIDの場合" do
      it "AssignHistoryを返すこと" do
        result = repository.find_assign_history_with_lock(assign_history.id)
        expect(result).to eq(assign_history)
      end
    end

    context "存在しないIDの場合" do
      it "nilを返すこと" do
        result = repository.find_assign_history_with_lock(999999)
        expect(result).to be_nil
      end
    end
  end

  describe "#complete_assign_history" do
    let!(:task) { create(:task, area:) }
    let!(:account) { create(:account) }
    let!(:assign_cycle) { create(:assign_cycle, task:) }
    let!(:assign_history) { create(:assign_history, assign_cycle:, account:, completed: false) }

    it "trueを返すこと" do
      result = repository.complete_assign_history(assign_history)
      expect(result).to be true
    end

    it "completedがtrueに更新されること" do
      repository.complete_assign_history(assign_history)
      expect(assign_history.reload.completed).to be true
    end

    it "completed_atが設定されること" do
      repository.complete_assign_history(assign_history)
      expect(assign_history.reload.completed_at).not_to be_nil
    end
  end

  describe "#deactivate_cycle" do
    let!(:task) { create(:task, area:) }
    let!(:assign_cycle) { create(:assign_cycle, task:, is_active: true) }

    it "trueを返すこと" do
      result = repository.deactivate_cycle(assign_cycle)
      expect(result).to be true
    end

    it "is_activeがfalseに更新されること" do
      repository.deactivate_cycle(assign_cycle)
      expect(assign_cycle.reload.is_active).to be false
    end
  end

  describe "#mark_ng" do
    let!(:task) { create(:task, area:) }
    let!(:account) { create(:account) }
    let!(:assign_cycle) { create(:assign_cycle, task:) }
    let!(:assign_history) { create(:assign_history, assign_cycle:, account:, ng: false) }

    it "trueを返すこと" do
      result = repository.mark_ng(assign_history)
      expect(result).to be true
    end

    it "ngがtrueに更新されること" do
      repository.mark_ng(assign_history)
      expect(assign_history.reload.ng).to be true
    end

    context "バリデーションエラーが発生した場合" do
      it "ActiveRecord::RecordInvalidを発生させること" do
        allow(assign_history).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(assign_history))
        expect { repository.mark_ng(assign_history) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#deactivate_all_cycles" do
    let!(:task) { create(:task, area:) }

    context "アクティブなサイクルがある場合" do
      let!(:cycle1) { create(:assign_cycle, task:, is_active: true) }
      let!(:cycle2) { create(:assign_cycle, task:, is_active: true) }

      it "全てのサイクルを非アクティブ化すること" do
        repository.deactivate_all_cycles(task)

        expect(cycle1.reload.is_active).to be false
        expect(cycle2.reload.is_active).to be false
      end

      it "更新された行数を返すこと" do
        result = repository.deactivate_all_cycles(task)
        expect(result).to eq(2)
      end
    end

    context "サイクルが存在しない場合" do
      it "エラーにならないこと" do
        expect { repository.deactivate_all_cycles(task) }.not_to raise_error
      end

      it "0を返すこと" do
        result = repository.deactivate_all_cycles(task)
        expect(result).to eq(0)
      end
    end

    context "他のタスクのサイクルがある場合" do
      let!(:other_task) { create(:task, area:) }
      let!(:cycle) { create(:assign_cycle, task:, is_active: true) }
      let!(:other_cycle) { create(:assign_cycle, task: other_task, is_active: true) }

      it "指定タスクのサイクルのみ非アクティブ化すること" do
        repository.deactivate_all_cycles(task)

        expect(cycle.reload.is_active).to be false
        expect(other_cycle.reload.is_active).to be true
      end
    end
  end

  describe "#create_cycle" do
    let!(:task) { create(:task, area:) }

    it "新しいAssignCycleを作成すること" do
      expect {
        repository.create_cycle(task)
      }.to change(AssignCycle, :count).by(1)
    end

    it "作成されたAssignCycleを返すこと" do
      result = repository.create_cycle(task)
      expect(result).to be_a(AssignCycle)
      expect(result).to be_persisted
    end

    it "is_activeがtrueで作成されること" do
      result = repository.create_cycle(task)
      expect(result.is_active).to be true
    end

    it "指定したタスクに紐づくこと" do
      result = repository.create_cycle(task)
      expect(result.task_id).to eq(task.id)
    end

    context "バリデーションエラーが発生した場合" do
      it "ActiveRecord::RecordInvalidを発生させること" do
        # task_idがnilの場合など
        allow(task).to receive_message_chain(:assign_cycles, :create!).and_raise(ActiveRecord::RecordInvalid.new(AssignCycle.new))
        expect { repository.create_cycle(task) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#count_unfulfilleds" do
    let!(:task) { create(:task, area:) }

    context "アクティブなサイクルがある場合" do
      let!(:cycle1) { create(:assign_cycle, task:, is_active: true) }
      let!(:cycle2) { create(:assign_cycle, task:, is_active: true) }

      it "アクティブサイクル数を返すこと" do
        result = repository.count_unfulfilleds
        expect(result).to eq(2)
      end
    end

    context "アクティブなサイクルがない場合" do
      it "0を返すこと" do
        result = repository.count_unfulfilleds
        expect(result).to eq(0)
      end
    end

    context "非アクティブなサイクルがある場合" do
      let!(:active_cycle) { create(:assign_cycle, task:, is_active: true) }
      let!(:inactive_cycle) { create(:assign_cycle, task:, is_active: false) }

      it "アクティブサイクルのみカウントすること" do
        result = repository.count_unfulfilleds
        expect(result).to eq(1)
      end
    end

    context "複数タスクにアクティブサイクルがある場合" do
      let!(:task2) { create(:task, area:) }
      let!(:cycle1) { create(:assign_cycle, task:, is_active: true) }
      let!(:cycle2) { create(:assign_cycle, task: task2, is_active: true) }
      let!(:cycle3) { create(:assign_cycle, task: task2, is_active: false) }

      it "全タスクのアクティブサイクル合計を返すこと" do
        result = repository.count_unfulfilleds
        expect(result).to eq(2)
      end
    end
  end

  describe "#get_account_assign_tasks" do
    let!(:task) { create(:task, area:) }
    let!(:account) { create(:account) }
    let!(:other_account) { create(:account_member) }
    let!(:assign_cycle) { create(:assign_cycle, task:, is_active: true) }

    context "アクティブな割り当てがある場合" do
      let!(:history) { create(:assign_history, assign_cycle:, account:, completed: false, ng: false) }

      it "割り当てられたタスクを返すこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result.length).to eq(1)
        expect(result.first.id).to eq(task.id)
      end

      it "title属性を含むこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result.first).to respond_to(:title)
        expect(result.first.title).to eq(task.task_title)
      end

      it "area_name属性を含むこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result.first).to respond_to(:area_name)
        expect(result.first.area_name).to eq(area.name)
      end

      it "history_id属性を含むこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result.first).to respond_to(:history_id)
        expect(result.first.history_id).to eq(history.id)
      end

      it "assign_cycle_id属性を含むこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result.first).to respond_to(:assign_cycle_id)
        expect(result.first.assign_cycle_id).to eq(assign_cycle.id)
      end
    end

    context "完了済みの割り当てがある場合" do
      let!(:history) { create(:assign_history, assign_cycle:, account:, completed: true, ng: false) }

      it "空配列を返すこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result).to be_empty
      end
    end

    context "NG済みの割り当てがある場合" do
      let!(:history) { create(:assign_history, assign_cycle:, account:, completed: false, ng: true) }

      it "空配列を返すこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result).to be_empty
      end
    end

    context "非アクティブなサイクルの割り当てがある場合" do
      let!(:inactive_cycle) { create(:assign_cycle, task:, is_active: false) }
      let!(:history) { create(:assign_history, assign_cycle: inactive_cycle, account:, completed: false, ng: false) }

      it "空配列を返すこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result).to be_empty
      end
    end

    context "他のアカウントの割り当てがある場合" do
      let!(:history) { create(:assign_history, assign_cycle:, account: other_account, completed: false, ng: false) }

      it "空配列を返すこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result).to be_empty
      end
    end

    context "割り当てがない場合" do
      it "空配列を返すこと" do
        result = repository.get_account_assign_tasks(account.id)
        expect(result).to be_empty
      end
    end
  end

  describe "#get_completed_past_week" do
    let!(:task) { create(:task, area:) }
    let!(:cycle) { create(:assign_cycle, task:) }
    let!(:account) { create(:account) }

    context "過去1週間に完了履歴がある場合" do
      let!(:history1) { create(:assign_history, assign_cycle: cycle, account:, completed: true, completed_at: 1.day.ago) }
      let!(:history2) { create(:assign_history, assign_cycle: cycle, account:, completed: true, completed_at: 1.day.ago) }
      let!(:history3) { create(:assign_history, assign_cycle: cycle, account:, completed: true, completed_at: 2.days.ago) }

      it "日付別にグループ化されたハッシュを返すこと" do
        result = repository.get_completed_past_week
        expect(result).to be_a(Hash)
      end

      it "各日付のカウントが正しいこと" do
        result = repository.get_completed_past_week
        # 1.day.agoの日付に2件、2.days.agoの日付に1件
        expect(result.values.sum).to eq(3)
      end
    end

    context "過去1週間に完了履歴がない場合" do
      it "空のハッシュを返すこと" do
        result = repository.get_completed_past_week
        expect(result).to eq({})
      end
    end

    context "1週間以上前の完了履歴のみの場合" do
      let!(:old_history) { create(:assign_history, assign_cycle: cycle, account:, completed: true, completed_at: 10.days.ago) }

      it "空のハッシュを返すこと" do
        result = repository.get_completed_past_week
        expect(result).to eq({})
      end
    end
  end
end
