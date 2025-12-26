# frozen_string_literal: true

module Services
  module AccountAreas
    # アカウント-エリア操作の結果を表すStruct
    # @!attribute success?
    #   @return [Boolean] 操作が成功したかどうか
    # @!attribute areas
    #   @return [Array<Area>, nil] エリア一覧
    # @!attribute message
    #   @return [String, nil] 結果メッセージ
    # @!attribute errors
    #   @return [Array<String>] エラーメッセージ配列
    # @!attribute status
    #   @return [Symbol] HTTPステータスシンボル
    Result = Struct.new(:success?, :areas, :message, :errors, :status, keyword_init: true)
  end
end
