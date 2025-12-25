# frozen_string_literal: true

module Services
  module Areas
    # Area モデルへのデータアクセスを担当するリポジトリ
    #
    # Service 層から直接 ActiveRecord を呼び出さないための抽象化層
    # テスト時にモック化することで DB 非依存のテストが可能
    class Repository
      # 全エリアを取得（id, name のみ選択）
      # @return [ActiveRecord::Relation<Area>]
      def all_areas
        Area.select(:id, :name)
      end

      # IDでエリアを検索
      # @param id [Integer] エリアID
      # @return [Area, nil]
      def find_by_id(id)
        Area.find_by(id:)
      end

      # IDでエリアを悲観ロック付きで検索
      # 同時更新を防ぐため、update/destroy 処理で使用
      # @param id [Integer] エリアID
      # @return [Area, nil]
      def find_by_id_with_lock(id)
        Area.lock.find_by(id:)
      end

      # 新規 Area インスタンスを生成（未保存）
      # @param attrs [Hash] エリア属性
      # @return [Area]
      def build(attrs)
        Area.new(attrs)
      end

      # Area を永続化
      # @param area [Area] 保存対象のエリア
      # @return [Boolean] 保存成功/失敗
      def save(area)
        area.save
      end

      # Area の属性を更新
      # @param area [Area] 更新対象のエリア
      # @param attrs [Hash] 更新する属性
      # @return [Boolean] 更新成功/失敗
      def update(area, attrs)
        area.update(attrs)
      end

      # Area を削除
      # @param area [Area] 削除対象のエリア
      # @return [Boolean] 削除成功/失敗
      def destroy(area)
        area.destroy
      end
    end
  end
end
