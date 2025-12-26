# frozen_string_literal: true

module Services
  module Tags
    # タグのDBアクセスを担当
    #
    # 全メソッドにdebugログを出力
    class Repository
      def all_tags
        Rails.logger.debug "Repository: all_tags"
        Tag.select(:id, :name)
      end

      def find_by_id(id)
        Rails.logger.debug "Repository: find_by_id id=#{id}"
        Tag.find_by(id:)
      end

      def find_by_id_with_lock(id)
        Rails.logger.debug "Repository: find_by_id_with_lock id=#{id}"
        Tag.lock.find_by(id:)
      end

      def build(attrs)
        Rails.logger.debug "Repository: build attrs=#{attrs.keys.join(', ')}"
        Tag.new(attrs)
      end

      def save(tag)
        Rails.logger.debug "Repository: save id=#{tag.id || 'new'}"
        result = tag.save
        Rails.logger.debug "Repository: save result=#{result}"
        result
      end

      def update(tag, attrs)
        Rails.logger.debug "Repository: update id=#{tag.id}, attrs=#{attrs.keys.join(', ')}"
        result = tag.update(attrs)
        Rails.logger.debug "Repository: update result=#{result}"
        result
      end

      # タグを削除
      # @param tag [Tag] 削除対象のタグ
      # @return [Boolean] 削除成功/失敗
      def destroy(tag)
        Rails.logger.debug "Repository: destroy id=#{tag.id}"
        tag.destroy
        destroyed = tag.destroyed?
        Rails.logger.debug "Repository: destroy result=#{destroyed ? 'success' : 'failed'}"
        destroyed
      end
    end
  end
end
