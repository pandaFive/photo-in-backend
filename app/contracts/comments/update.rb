# frozen_string_literal: true

module Contracts
  module Comments
    # コメント更新用コントラクト
    #
    # 検証ルール:
    # - id: 必須、正の整数のみ
    # - content: 任意、最大1000文字
    #
    # パラメータ形式:
    # - { id: ..., comment: { content: "..." } }
    #
    # 注意: content が nil の場合、更新対象から除外される（既存値を維持）
    class Update
      include ActiveModel::Model

      attr_accessor :id, :content

      validates :id, presence: true
      validates :id, numericality: { only_integer: true, greater_than: 0 }, if: -> { id.present? }
      validates :content, length: { maximum: 1000 }, allow_nil: true

      def self.call(params)
        comment_params = params[:comment] || {}
        contract = new(
          id: params[:id],
          content: comment_params[:content]
        )

        if contract.valid?
          Contracts::Result.new(success?: true, value: contract.normalized_attributes, errors: [])
        else
          Contracts::Result.new(success?: false, value: nil, errors: contract.errors.full_messages)
        end
      end

      def normalized_attributes
        { id: id.to_i, content: }.compact
      end
    end
  end
end
