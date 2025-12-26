# frozen_string_literal: true

module Contracts
  module TagAccounts
    # タグ追加の入力検証
    # @param params [Hash] { account_id: Integer, tag_id: Integer }
    # @return [Contracts::Result]
    class Create
      include ActiveModel::Model

      attr_accessor :account_id, :tag_id

      validates :account_id, presence: { message: "アカウントIDは必須です" }
      validates :account_id, numericality: { only_integer: true, greater_than: 0, message: "アカウントIDは正の整数である必要があります" }, if: -> { account_id.present? }
      validates :tag_id, presence: { message: "タグIDは必須です" }
      validates :tag_id, numericality: { only_integer: true, greater_than: 0, message: "タグIDは正の整数である必要があります" }, if: -> { tag_id.present? }

      def self.call(params)
        contract = new(
          account_id: params[:account_id],
          tag_id: params[:tag_id]
        )

        if contract.valid?
          Contracts::Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Contracts::Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        { account_id: account_id.to_i, tag_id: tag_id.to_i }
      end
    end
  end
end
