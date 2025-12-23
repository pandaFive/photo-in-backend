module Presenters
  class AccountPresenter
    def self.render_auth(account)
      token = JsonWebToken.encode({ account_id: account.id })
      {
        account: {
          id: account.id,
          role: account.role,
          token:,
          name: account.name
        }
      }
    end

    def self.render_account(account)
      {
        id: account.id,
        createdAt: account.created_at,
        capacity: account.capacity,
        updatedAt: account.updated_at,
        name: account.name,
        role: account.role
      }
    end

    def self.render_accounts(accounts, stats_by_account)
      accounts.map do |account|
        stats = stats_by_account[account.id]
        total = stats&.total_count.to_i
        ng_count = stats&.ng_count.to_i
        ng_rate = total.zero? ? 0.0 : (ng_count.to_f / total).floor(2)

        {
          id: account.id,
          capacity: account.capacity,
          createdAt: account.created_at,
          updatedAt: account.updated_at,
          name: account.name,
          area: account.areas.map(&:name),
          total:,
          week: stats&.week_count.to_i,
          ng_rate:,
          assign: stats&.assign_count.to_i
        }
      end
    end
  end
end
