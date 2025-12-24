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

      # アクティブなタスク一覧を取得
      def list_active_tasks
        Task.get_active_tasks
      end

      # NG状態のタスク一覧を取得
      def list_ng_tasks
        Task.get_ng_tasks
      end
    end
  end
end
