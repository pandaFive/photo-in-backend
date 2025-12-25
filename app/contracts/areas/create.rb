# frozen_string_literal: true

module Contracts
  module Areas
    # エリア作成用コントラクト
    #
    # 検証ルール:
    # - name: 必須、最大32文字
    #
    # パラメータ形式:
    # - { name: "..." } または { area: { name: "..." } }
    class Create
      include ActiveModel::Model

      attr_accessor :name

      validates :name, presence: true, length: { maximum: 32 }

      def self.call(params)
        contract = new(name: params.dig(:area, :name) || params[:name])

        if contract.valid?
          Contracts::Result.new(success?: true, value: { name: contract.name }, errors: [])
        else
          Contracts::Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end
    end
  end
end
