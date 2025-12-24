# frozen_string_literal: true

module Services
  module Tasks
    # Unified Result for Tasks services.
    # task: 単一リソース（create/show等）
    # tasks: コレクション（index等）
    Result = Struct.new(:success?, :task, :tasks, :errors, :status, keyword_init: true)
  end
end
