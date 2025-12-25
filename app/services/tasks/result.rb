# frozen_string_literal: true

module Services
  module Tasks
    # Tasks サービス共通 Result
    #
    # 全サービスで統一して使用するResult Struct
    # 使用しないフィールドはnilのまま
    #
    # @attr success? [Boolean] 処理成功/失敗
    # @attr task [Task, nil] 単一タスクリソース
    # @attr tasks [Array, nil] タスクコレクション
    # @attr message [String, nil] 処理結果メッセージ（状態変更系サービス）
    # @attr count [Integer, nil] カウント値
    # @attr data [Hash, nil] 汎用データ
    # @attr errors [Array<String>] エラーメッセージ配列
    # @attr status [Symbol] HTTPステータス（:ok, :created, :not_found等）
    Result = Struct.new(
      :success?,
      :task,
      :tasks,
      :message,
      :count,
      :data,
      :errors,
      :status,
      keyword_init: true
    )
  end
end
