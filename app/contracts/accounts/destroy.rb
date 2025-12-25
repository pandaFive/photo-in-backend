# frozen_string_literal: true

module Contracts
  module Accounts
    # アカウント削除用Contract
    #
    # IDのみを検証（IdContractを継承）
    class Destroy < IdContract
    end
  end
end
