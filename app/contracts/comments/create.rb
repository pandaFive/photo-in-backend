# frozen_string_literal: true

module Contracts
  module Comments
    # コメント作成用コントラクト
    #
    # 検証ルール:
    # - content: 必須、最大1000文字
    # - task_id: 必須、正の整数のみ
    #
    # パラメータ形式:
    # - { comment: { content: "...", task_id: ... } }
    #
    # 注意: account_id はパラメータから受け取らず、current_account から設定
    class Create
      include ActiveModel::Model

      attr_accessor :content, :task_id

      validates :content, presence: true, length: { maximum: 1000 }
      validates :task_id, presence: true
      validates :task_id, numericality: { only_integer: true, greater_than: 0 }, if: -> { task_id.present? }

      def self.call(params)
        comment_params = params[:comment] || {}
        contract = new(
          content: comment_params[:content],
          task_id: comment_params[:task_id]
        )

        if contract.valid?
          Contracts::Result.new(
            success?: true,
            value: { content: contract.content, task_id: contract.task_id.to_i },
            errors: []
          )
        else
          Contracts::Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end
    end
  end
end
