# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Assigns::Repository, type: :service do
  let(:repository) { described_class.new }
  let!(:area) { create(:area) }

  describe "#find_task_with_lock" do
    let!(:task) { create(:task, area:) }

    context "存在するIDの場合" do
      it "タスクを返すこと" do
        result = repository.find_task_with_lock(task.id)
        expect(result).to eq(task)
      end
    end

    context "存在しないIDの場合" do
      it "nilを返すこと" do
        result = repository.find_task_with_lock(999999)
        expect(result).to be_nil
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
        allow(task).to receive_message_chain(:assign_cycles, :create!).and_raise(ActiveRecord::RecordInvalid.new(AssignCycle.new))
        expect { repository.create_cycle(task) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
