# frozen_string_literal: true

module Contracts
  module Tags
    # タグ作成の入力検証
    class Create
      include ActiveModel::Model

      attr_accessor :name

      validates :name, presence: true, length: { maximum: 32 }

      def self.call(params)
        contract = new(name: params.dig(:tag, :name) || params[:name])
        if contract.valid?
          ::Contracts::Result.new(success?: true, value: { name: contract.name }, errors: [])
        else
          ::Contracts::Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end
    end
  end
end
