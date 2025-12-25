# frozen_string_literal: true

module Services
  module Accounts
    # Accounts サービス共通 Result
    #
    # 全サービスで統一して使用するResult Struct
    # 使用しないフィールドはnilのまま
    #
    # @attr success? [Boolean] 処理成功/失敗
    # @attr account [Account, nil] 単一リソース（show/create/update等）
    # @attr accounts [Array, nil] コレクション（index等）
    # @attr message [String, nil] 処理結果メッセージ（destroy等）
    # @attr data [Hash, nil] 統計データ等（index: アカウントごとの割当統計）
    # @attr errors [Array<String>] エラーメッセージ配列
    # @attr status [Symbol] HTTPステータス（:ok, :created, :not_found等）
    Result = Struct.new(
      :success?,
      :account,
      :accounts,
      :message,
      :data,
      :errors,
      :status,
      keyword_init: true
    )
  end
end
