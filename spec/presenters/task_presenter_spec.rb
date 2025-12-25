# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presenters::TaskPresenter, type: :presenter do
  describe ".render_account_assign_tasks" do
    # get_account_assign_tasksが返すオブジェクトをシミュレート
    let(:task_data) do
      Struct.new(:id, :title, :area_name, :history_id, :assign_cycle_id, :created_at, keyword_init: true)
    end

    context "タスクがある場合" do
      let(:tasks) do
        [
          task_data.new(
            id: 1,
            title: "タスク1",
            area_name: "エリア1",
            history_id: 10,
            assign_cycle_id: 5,
            created_at: Time.zone.parse("2025-12-25 10:00:00")
          ),
          task_data.new(
            id: 2,
            title: "タスク2",
            area_name: "エリア2",
            history_id: 11,
            assign_cycle_id: 6,
            created_at: Time.zone.parse("2025-12-25 11:00:00")
          )
        ]
      end

      it "配列を返すこと" do
        result = described_class.render_account_assign_tasks(tasks)
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
      end

      it "titleをtask_titleに変換すること" do
        result = described_class.render_account_assign_tasks(tasks)
        expect(result.first[:task_title]).to eq("タスク1")
        expect(result.first).not_to have_key(:title)
      end

      it "必要なキーを含むこと" do
        result = described_class.render_account_assign_tasks(tasks)
        expected_keys = [:id, :task_title, :area_name, :history_id, :assign_cycle_id, :created_at]
        expect(result.first.keys).to match_array(expected_keys)
      end

      it "各フィールドが正しい値であること" do
        result = described_class.render_account_assign_tasks(tasks)
        first_task = result.first

        expect(first_task[:id]).to eq(1)
        expect(first_task[:task_title]).to eq("タスク1")
        expect(first_task[:area_name]).to eq("エリア1")
        expect(first_task[:history_id]).to eq(10)
        expect(first_task[:assign_cycle_id]).to eq(5)
        expect(first_task[:created_at]).to eq(Time.zone.parse("2025-12-25 10:00:00"))
      end
    end

    context "タスクが空の場合" do
      it "空配列を返すこと" do
        result = described_class.render_account_assign_tasks([])
        expect(result).to eq([])
      end
    end
  end
end
