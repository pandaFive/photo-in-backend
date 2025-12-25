# frozen_string_literal: true

module Services
  module Accounts
    # アカウント関連のデータアクセス層
    #
    # DBアクセスをカプセル化し、Serviceレイヤから利用される
    class Repository
      # 新規アカウントオブジェクトを構築
      def build(attrs)
        Account.new(attrs)
      end

      # 指定IDのエリアを取得
      def find_areas(area_ids)
        ids = Array(area_ids).compact
        return Area.none if ids.empty?

        Area.where(id: ids)
      end

      # アカウントにエリアを関連付け
      def assign_areas(account, areas)
        return if areas.empty?

        account.areas = areas
      end

      # アカウントを保存
      def save(account)
        account.save
      end

      # アカウントを更新
      def update(account, attrs)
        account.update(attrs)
      end

      # アカウントを削除
      def destroy(account)
        account.destroy
      end

      # メンバー一覧を取得（エリア情報含む）
      def list_members
        Account.where(role: "member").includes(:areas)
      end

      # IDでアカウントを取得
      def get_account(id)
        Account.find_by(id:)
      end

      # メンバーごとの割当統計を取得
      #
      # @param members [ActiveRecord::Relation] 対象のアカウント一覧
      # @return [Hash{Integer => AssignHistory}] account_id をキーとした統計オブジェクト
      #   - total_count: 累計完了数
      #   - week_count: 直近1週間の完了数
      #   - assign_count: 現在割当中（未完了かつNG以外）
      #   - ng_count: NG件数
      def get_accounts_stats(members)
        cutoff = 1.week.ago
        AssignHistory
          .where(account_id: members.select(:id))
          .group(:account_id)
          .select(
            :account_id,
            Arel.sql("COUNT(*) FILTER (WHERE completed IS TRUE) AS total_count"),
            Arel.sql(
              AssignHistory.sanitize_sql_array(
                ["COUNT(*) FILTER (WHERE completed_at > ?) AS week_count", cutoff]
              )
            ),
            Arel.sql("COUNT(*) FILTER (WHERE ng IS FALSE AND completed IS FALSE) AS assign_count"),
            Arel.sql("COUNT(*) FILTER (WHERE ng IS TRUE) AS ng_count")
          ).index_by(&:account_id)
      end
    end
  end
end
