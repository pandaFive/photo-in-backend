# frozen_string_literal: true

module Services
  module AccountAreas
    # アカウント-エリア操作用のリポジトリ
    class Repository
      # アカウントをIDで取得
      # @param account_id [Integer] アカウントID
      # @return [Account, nil]
      def find_account(account_id)
        Account.find_by(id: account_id)
      end

      # エリアをIDで取得
      # @param area_id [Integer] エリアID
      # @return [Area, nil]
      def find_area(area_id)
        Area.find_by(id: area_id)
      end

      # アカウントにエリアが既に紐付いているか確認
      # @param account [Account]
      # @param area [Area]
      # @return [Boolean]
      def area_exists?(account, area)
        account.areas.exists?(area.id)
      end

      # アカウントにエリアを追加
      # @param account [Account]
      # @param area [Area]
      # @return [Boolean] 追加成功時true、重複時false
      def add_area(account, area)
        account.areas << area
        true
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.warn "AccountArea add_area race condition: account_id=#{account.id}, area_id=#{area.id}, error=#{e.message}"
        false
      end

      # アカウントからエリアを削除
      # @param account [Account]
      # @param area [Area]
      # @return [Boolean] 削除成功時true、失敗時false
      def remove_area(account, area)
        result = account.areas.destroy(area)
        result.present?
      rescue ActiveRecord::RecordNotDestroyed => e
        Rails.logger.error "AccountArea remove_area failed: account_id=#{account.id}, area_id=#{area.id}, error=#{e.message}"
        false
      end

      # アカウントのエリア一覧を取得
      # @param account [Account]
      # @return [Array<Area>]
      def get_areas(account)
        account.areas
      end
    end
  end
end
