# frozen_string_literal: true

module Services
  module TagAccounts
    # アカウント-タグ操作の結果を表すStruct
    # @!attribute success?
    #   @return [Boolean] 操作が成功したかどうか
    # @!attribute tags
    #   @return [Array<Tag>, nil] タグ一覧
    # @!attribute message
    #   @return [String, nil] 結果メッセージ
    # @!attribute errors
    #   @return [Array<String>] エラーメッセージ配列
    # @!attribute status
    #   @return [Symbol] HTTPステータスシンボル
    Result = Struct.new(:success?, :tags, :message, :errors, :status, keyword_init: true)
  end
end
