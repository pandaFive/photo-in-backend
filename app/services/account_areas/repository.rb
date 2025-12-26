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
      # @return [Boolean] 追加成功時true
      def add_area(account, area)
        account.areas << area
        true
      rescue ActiveRecord::RecordNotUnique
        false
      end

      # アカウントからエリアを削除
      # @param account [Account]
      # @param area [Area]
      # @return [Boolean] 削除成功時true
      def remove_area(account, area)
        account.areas.destroy(area)
        true
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
