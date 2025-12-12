class Account < ApplicationRecord
  validates :name, presence: true, length: { maximum: 32 }
  has_secure_password
  validates :password, presence: true, length: { minimum: 8 }, allow_nil: true

  has_many :account_areas
  has_many :areas, through: :account_areas

  has_many :tag_accounts
  has_many :tags, through: :tag_accounts

  has_many :comments
  has_many :completed_tasks
  has_many :ng_histories
  has_many :assign_histories

  def add_area(area)
    self.areas << area
  end

  def add_areas(areas)
    areas.each do |area|
      add_area(Area.find(area.to_i))
    end
  end

  def remove_area(area)
    self.areas.destroy(area)
  end

  def add_tag(tag)
    self.tags << tag
  end

  def remove_tag(tag)
    self.tags.destroy(tag)
  end

  # 単一アカウントのステータスを取得（1クエリで集計）
  def get_status
    stats = AssignHistory.where(account_id: id)
              .select(
                "COUNT(CASE WHEN completed = true THEN 1 END) AS total_count",
                "COUNT(CASE WHEN completed_at > '#{1.week.ago.to_fs(:db)}' THEN 1 END) AS week_count",
                "COUNT(CASE WHEN ng = false AND completed = false THEN 1 END) AS assign_count",
                "COUNT(CASE WHEN ng = true THEN 1 END) AS ng_count"
              ).take

    total = stats&.total_count.to_i
    ng_count = stats&.ng_count.to_i
    ng_rate = total.zero? ? 0.0 : (ng_count.to_f / total).floor(2)

    {
      id:,
      capacity:,
      createdAt: created_at,
      updatedAt: updated_at,
      name:,
      area: areas.pluck(:name),
      total:,
      week: stats&.week_count.to_i,
      ng_rate:,
      assign: stats&.assign_count.to_i
    }
  end

  class << self
    # 全メンバーのステータスをバッチ取得（N+1を回避）
    def get_role_one_status
      members = Account.where(role: "member").includes(:areas)

      # 全メンバーの統計を一括取得
      stats_by_account = AssignHistory
        .where(account_id: members.pluck(:id))
        .group(:account_id)
        .select(
          :account_id,
          "COUNT(CASE WHEN completed = true THEN 1 END) AS total_count",
          "COUNT(CASE WHEN completed_at > '#{1.week.ago.to_fs(:db)}' THEN 1 END) AS week_count",
          "COUNT(CASE WHEN ng = false AND completed = false THEN 1 END) AS assign_count",
          "COUNT(CASE WHEN ng = true THEN 1 END) AS ng_count"
        ).index_by(&:account_id)

      members.map do |account|
        stats = stats_by_account[account.id]
        total = stats&.total_count.to_i
        ng_count = stats&.ng_count.to_i
        ng_rate = total.zero? ? 0.0 : (ng_count.to_f / total).floor(2)

        {
          id: account.id,
          capacity: account.capacity,
          createdAt: account.created_at,
          updatedAt: account.updated_at,
          name: account.name,
          area: account.areas.map(&:name),
          total:,
          week: stats&.week_count.to_i,
          ng_rate:,
          assign: stats&.assign_count.to_i
        }
      end
    end
  end
end
