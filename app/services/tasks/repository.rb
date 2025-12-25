# frozen_string_literal: true

module Services
  module Tasks
    class Repository
      def build(attrs)
        Task.new(attrs)
      end

      # IDでタスクを取得
      def find_by_id(id)
        Task.find_by(id:)
      end

      # IDでタスクを取得（悲観的ロック付き - レースコンディション防止）
      def find_by_id_with_lock(id)
        Task.lock.find_by(id:)
      end

      # タイトルからエリアを推論
      def infer_area_id(title)
        Area.get_area_id(title)
      end

      # デフォルトエリア（最初のエリア）のIDを取得
      def default_area_id
        Area.first&.id
      end

      def save(task)
        task.save
      end

      # タスクを更新
      def update(task, attrs)
        task.update(attrs)
      end

      # タスクを削除
      def delete(task)
        task.destroy
      end

      # アクティブなタスク一覧を取得
      def list_active_tasks
        Task.get_active_tasks
      end

      # NG状態のタスク一覧を取得
      def list_ng_tasks
        Task.get_ng_tasks
      end

      # タグをIDで取得
      def find_tag(id)
        Tag.find_by(id:)
      end

      # タスクにタグを追加
      def add_tag(task, tag)
        return false if task.tags.include?(tag)

        task.tags << tag
        true
      end

      # タスクからタグを削除
      def remove_tag(task, tag)
        return false unless task.tags.include?(tag)

        task.tags.delete(tag)
        true
      end

      # AssignHistoryをIDで取得（悲観的ロック付き - 同時完了操作によるレースコンディション防止）
      def find_assign_history_with_lock(id)
        AssignHistory.lock.find_by(id:)
      end

      # AssignHistoryの完了処理（Service層からの呼び出し用）
      # @raise [ActiveRecord::RecordInvalid] バリデーション失敗時
      def complete_assign_history(assign_history)
        assign_history.update!(completed: true, completed_at: Time.current)
      end

      # AssignCycleの非アクティブ化
      # @raise [ActiveRecord::RecordInvalid] バリデーション失敗時
      def deactivate_cycle(cycle)
        cycle.update!(is_active: false)
      end

      # AssignHistoryのNG処理（Service層からの呼び出し用）
      # @raise [ActiveRecord::RecordInvalid] バリデーション失敗時
      def mark_ng(assign_history)
        assign_history.update!(ng: true)
      end
    end
  end
end
