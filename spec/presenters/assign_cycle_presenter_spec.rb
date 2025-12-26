# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presenters::AssignCyclePresenter do
  describe ".render_cycle" do
    context "有効なサイクルの場合" do
      let!(:area) { create(:area) }
      let!(:task) { create(:task, area:) }
      let!(:cycle) { create(:assign_cycle, task:, is_active: true) }

      it "正しいハッシュを返すこと" do
        result = described_class.render_cycle(cycle)
        expect(result).to eq({
          id: cycle.id,
          task_id: cycle.task_id,
          is_active: true,
          created_at: cycle.created_at,
          updated_at: cycle.updated_at
        })
      end

      it "idを含むこと" do
        result = described_class.render_cycle(cycle)
        expect(result[:id]).to eq(cycle.id)
      end

      it "task_idを含むこと" do
        result = described_class.render_cycle(cycle)
        expect(result[:task_id]).to eq(task.id)
      end

      it "is_activeを含むこと" do
        result = described_class.render_cycle(cycle)
        expect(result[:is_active]).to be true
      end

      it "created_atを含むこと" do
        result = described_class.render_cycle(cycle)
        expect(result[:created_at]).to eq(cycle.created_at)
      end

      it "updated_atを含むこと" do
        result = described_class.render_cycle(cycle)
        expect(result[:updated_at]).to eq(cycle.updated_at)
      end
    end

    context "is_activeがfalseのサイクルの場合" do
      let!(:area) { create(:area) }
      let!(:task) { create(:task, area:) }
      let!(:cycle) { create(:assign_cycle, task:, is_active: false) }

      it "is_activeがfalseであること" do
        result = described_class.render_cycle(cycle)
        expect(result[:is_active]).to be false
      end
    end

    context "cycleがnilの場合" do
      it "ArgumentErrorを発生させること" do
        expect {
          described_class.render_cycle(nil)
        }.to raise_error(ArgumentError, "AssignCyclePresenter.render_cycle received nil cycle")
      end
    end
  end
end
