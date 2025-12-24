# frozen_string_literal: true

module Services
  class AssignableAccountsService
    # キャパシティの何倍まで許容するか
    CAPACITY_MULTIPLIER = 4

    def initialize(assign_cycle:)
      @assign_cycle = assign_cycle
      @task = assign_cycle.task
    end

    def call
      return Account.none unless @task

      area_id = @task.area_id

      # 既にこのcycleでアサインされた（NGを含む）Accountを除外
      assigned_account_ids = Account
        .joins(assign_histories: :assign_cycle)
        .where(assign_cycles: { id: @assign_cycle.id })
        .select(:id)

      # キャパシティオーバーのAccountを除外
      over_capacity_account_ids = Account
        .joins(:areas)
        .left_outer_joins(assign_histories: :assign_cycle)
        .where(areas: { id: area_id })
        .where("assign_histories.ng = false OR assign_histories.ng IS NULL")
        .where("assign_histories.completed = false OR assign_histories.completed IS NULL")
        .group("accounts.id")
        .having("COUNT(assign_histories.id) >= accounts.capacity * ?", CAPACITY_MULTIPLIER)
        .select(:id)

      # エリア合致、未アサイン、キャパ範囲内のAccountを取得
      Account
        .joins(:areas)
        .where(areas: { id: area_id })
        .where.not(id: assigned_account_ids)
        .where.not(id: over_capacity_account_ids)
    end
  end
end
