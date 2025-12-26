# frozen_string_literal: true

module Services
  module Tags
    # タグサービスの結果オブジェクト
    Result = Struct.new(
      :success?,
      :tag,
      :tags,
      :message,
      :errors,
      :status,
      keyword_init: true
    )
  end
end
