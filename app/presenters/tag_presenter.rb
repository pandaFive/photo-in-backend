# frozen_string_literal: true

module Presenters
  # タグのレスポンス整形を担当
  class TagPresenter
    class << self
      # 単一タグをレスポンス形式に変換
      # @param tag [Tag] タグオブジェクト
      # @return [Hash]
      # @raise [ArgumentError] tag が nil の場合
      def render_tag(tag)
        raise ArgumentError, "TagPresenter.render_tag received nil tag" if tag.nil?

        { id: tag.id, name: tag.name }
      end

      # タグ一覧をレスポンス形式に変換
      # @param tags [Array<Tag>] タグ配列
      # @return [Array<Hash>]
      # @raise [ArgumentError] tags が nil の場合
      def render_tags(tags)
        raise ArgumentError, "TagPresenter.render_tags received nil tags" if tags.nil?

        tags.map { |tag| render_tag(tag) }
      end
    end
  end
end
