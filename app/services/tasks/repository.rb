module Services
  module Tasks
    class Repository
      def build(attrs)
        Task.new(attrs)
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
    end
  end
end
