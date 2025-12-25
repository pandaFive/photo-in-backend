# frozen_string_literal: true

module Services
  module Areas
    # Areas サービスの結果を格納する構造体
    # success?: 処理成功フラグ
    # area: 単一エリア（show/create/update）
    # areas: エリア一覧（index）
    # message: メッセージ（destroy成功時など）
    # errors: エラーメッセージ配列
    # status: HTTPステータスシンボル
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
