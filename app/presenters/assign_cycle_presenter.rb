# frozen_string_literal: true

module Presenters
  # サイクルのレスポンス整形を担当
  class AssignCyclePresenter
    class << self
      # 単一サイクルをレスポンス形式に変換
      # @param cycle [AssignCycle] サイクルオブジェクト
      # @return [Hash]
      # @raise [ArgumentError] cycle が nil の場合
      def render_cycle(cycle)
        raise ArgumentError, "AssignCyclePresenter.render_cycle received nil cycle" if cycle.nil?

        {
          id: cycle.id,
          task_id: cycle.task_id,
          is_active: cycle.is_active,
          created_at: cycle.created_at,
          updated_at: cycle.updated_at
        }
      end
    end
  end
end
