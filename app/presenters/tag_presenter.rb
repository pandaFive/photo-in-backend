# frozen_string_literal: true

module Presenters
  # タグのレスポンス整形を担当
  class TagPresenter
    class << self
      # 単一タグをレスポンス形式に変換
      # @param tag [Tag] タグオブジェクト
      # @return [Hash, nil]
      def render_tag(tag)
        if tag.nil?
          Rails.logger.warn "TagPresenter.render_tag received nil tag"
          return nil
        end

        { id: tag.id, name: tag.name }
      end

      # タグ一覧をレスポンス形式に変換
      # @param tags [Array<Tag>] タグ配列
      # @return [Array<Hash>]
      def render_tags(tags)
        if tags.nil?
          Rails.logger.warn "TagPresenter.render_tags received nil tags"
          return []
        end

        tags.map { |tag| render_tag(tag) }
      end
    end
  end
end
