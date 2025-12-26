# frozen_string_literal: true

module Contracts
  module Comments
    # コメント一覧取得用コントラクト
    #
    # 検証ルール:
    # - task_id: 必須、正の整数のみ
    #
    # パラメータ形式:
    # - { task_id: ... }
    class Index
      include ActiveModel::Model

      attr_accessor :task_id

      validates :task_id, presence: true
      validates :task_id, numericality: { only_integer: true, greater_than: 0 }, if: -> { task_id.present? }

      def self.call(params)
        contract = new(task_id: params[:task_id])

        if contract.valid?
          Contracts::Result.new(success?: true, value: { task_id: contract.task_id.to_i }, errors: [])
        else
          Contracts::Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end
    end
  end
end
