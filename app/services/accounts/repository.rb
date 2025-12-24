# frozen_string_literal: true

module Services
  module Accounts
    class Repository
      def build(attrs)
        Account.new(attrs)
      end

      def find_areas(area_ids)
        ids = Array(area_ids).compact
        return Area.none if ids.empty?

        Area.where(id: ids)
      end

      def assign_areas(account, areas)
        return if areas.empty?

        account.areas = areas
      end

      def save(account)
        account.save
      end

      def list_members
        Account.where(role: "member").includes(:areas)
      end

      def get_account(id)
        Account.find_by(id:)
      end

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
