# frozen_string_literal: true

module Contracts
  module AccountAreas
    # エリア削除の入力検証
    # params: { account_id: Integer, area_id: Integer }
    class Destroy
      include ActiveModel::Model

      attr_accessor :account_id, :area_id

      validates :account_id, presence: { message: "アカウントIDは必須です" }
      validates :account_id, numericality: { only_integer: true, greater_than: 0, message: "アカウントIDは正の整数である必要があります" }, if: -> { account_id.present? }
      validates :area_id, presence: { message: "エリアIDは必須です" }
      validates :area_id, numericality: { only_integer: true, greater_than: 0, message: "エリアIDは正の整数である必要があります" }, if: -> { area_id.present? }

      def self.call(params)
        contract = new(
          account_id: params[:account_id],
          area_id: params[:area_id]
        )

        if contract.valid?
          Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        { account_id: account_id.to_i, area_id: area_id.to_i }
      end
    end
  end
end
