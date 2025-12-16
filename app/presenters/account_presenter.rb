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
end
