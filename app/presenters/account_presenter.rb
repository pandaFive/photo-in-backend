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
        name: account.name
      }
    end
  end
end
