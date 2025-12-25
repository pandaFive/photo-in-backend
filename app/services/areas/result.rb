# frozen_string_literal: true

module Services
  module Areas
    # Areas サービス共通 Result
    #
    # 全サービスで統一して使用するResult Struct
    # 使用しないフィールドはnilのまま
    #
    # @attr success? [Boolean] 処理成功/失敗
    # @attr area [Area, nil] 単一リソース（show/create/update）
    # @attr areas [Array<Area>, nil] コレクション（index）
    # @attr message [String, nil] 処理結果メッセージ（destroy成功時）
    # @attr errors [Array<String>] エラーメッセージ配列
    # @attr status [Symbol] HTTPステータス（:ok, :created, :not_found等）
    Result = Struct.new(
      :success?,
      :area,
      :areas,
      :message,
      :errors,
      :status,
      keyword_init: true
    )
  end
end
