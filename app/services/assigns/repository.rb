# frozen_string_literal: true

module Services
  module Assigns
    # サイクル作成用のリポジトリ
    class Repository
      # タスクをIDで取得（悲観的ロック付き）
      # @param task_id [Integer] タスクID
      # @return [Task, nil]
      def find_task_with_lock(task_id)
        Task.lock.find_by(id: task_id)
      end

      # タスクの全サイクルを非アクティブ化
      # @param task [Task]
      # @return [Integer] 更新された行数
      def deactivate_all_cycles(task)
        AssignCycle.where(task_id: task.id).update_all(is_active: false)
      end

      # 新しいサイクルを作成
      # @param task [Task]
      # @return [AssignCycle]
      # @raise [ActiveRecord::RecordInvalid] バリデーション失敗時
      def create_cycle(task)
        task.assign_cycles.create!
      end
    end
  end
end
