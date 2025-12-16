module Accounts
  class Repository
    def build(attrs)
      Account.new(attrs)
    end

    def find_areas(area_ids)
      ids = Array(area_ids).compact
      return Area.none if ids.empty?

      Area.where(id: ids)
    end

    def assign_areas(account, areas)
      return if areas.empty?

      account.areas = areas
    end

    def save(account)
      account.save
    end
  end
end
