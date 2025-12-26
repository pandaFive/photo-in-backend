# frozen_string_literal: true

module Services
  module TagAccounts
    # アカウント-タグ操作用のリポジトリ
    class Repository
      # アカウントをIDで取得
      # @param account_id [Integer] アカウントID
      # @return [Account, nil]
      def find_account(account_id)
        Account.find_by(id: account_id)
      end

      # タグをIDで取得
      # @param tag_id [Integer] タグID
      # @return [Tag, nil]
      def find_tag(tag_id)
        Tag.find_by(id: tag_id)
      end

      # アカウントにタグが既に紐付いているか確認
      # @param account [Account]
      # @param tag [Tag]
      # @return [Boolean]
      def tag_exists?(account, tag)
        account.tags.exists?(tag.id)
      end

      # アカウントにタグを追加
      # @param account [Account]
      # @param tag [Tag]
      # @return [Boolean] 追加成功時true、重複時false
      def add_tag(account, tag)
        account.tags << tag
        true
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.warn "TagAccount add_tag race condition: account_id=#{account.id}, tag_id=#{tag.id}, error=#{e.message}"
        false
      end

      # アカウントからタグを削除
      # @param account [Account]
      # @param tag [Tag]
      # @return [Boolean] 削除成功時true、失敗時false
      def remove_tag(account, tag)
        result = account.tags.destroy(tag)
        result.present?
      rescue ActiveRecord::RecordNotDestroyed => e
        Rails.logger.error "TagAccount remove_tag failed: account_id=#{account.id}, tag_id=#{tag.id}, error=#{e.message}"
        false
      end

      # アカウントのタグ一覧を取得
      # @param account [Account]
      # @return [Array<Tag>]
      def get_tags(account)
        account.tags
      end
    end
  end
end
