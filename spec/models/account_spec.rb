require "rails_helper"

RSpec.describe Account, type: :model do
  describe "validations" do
    it "name, passwordが存在すれば有効であること" do
      account = Account.new(name: "Test User", password: "password123", role: "member", capacity: 3)
      expect(account).to be_valid
    end

    it "nameが存在しない場合は無効であること" do
      account = Account.new(name: nil, password: "password123", role: "member", capacity: 3)
      expect(account).not_to be_valid
    end

    it "nameが32文字を超える場合は無効であること" do
      account = Account.new(name: "a" * 33, password: "password123", role: "member", capacity: 3)
      expect(account).not_to be_valid
    end

    it "passwordが8文字未満の場合は無効であること" do
      account = Account.new(name: "Test User", password: "pass", role: "member", capacity: 3)
      expect(account).not_to be_valid
    end
  end

  describe "associations" do
    it "areasを持っていること" do
      association = Account.reflect_on_association(:areas)
      expect(association.macro).to eq(:has_many)
    end

    it "tagsを持っていること" do
      association = Account.reflect_on_association(:tags)
      expect(association.macro).to eq(:has_many)
    end

    it "commentsを持っていること" do
      association = Account.reflect_on_association(:comments)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe "#add_area" do
    it "アカウントにエリアを追加できること" do
      account = create(:account_member)
      area = create(:area)

      expect { account.add_area(area) }.to change { account.areas.count }.by(1)
      expect(account.areas).to include(area)
    end
  end

  describe "#add_areas" do
    it "アカウントに複数のエリアを追加できること" do
      account = create(:account_member)
      area1 = create(:area, name: "Area 1")
      area2 = create(:area, name: "Area 2")

      expect { account.add_areas([area1.id, area2.id]) }.to change { account.areas.count }.by(2)
      expect(account.areas).to include(area1, area2)
    end
  end

  describe "#remove_area" do
    it "アカウントからエリアを削除できること" do
      account = create(:account_member)
      area = create(:area)
      account.add_area(area)

      expect { account.remove_area(area) }.to change { account.areas.count }.by(-1)
      expect(account.areas).not_to include(area)
    end
  end

  describe "#add_tag" do
    it "アカウントにタグを追加できること" do
      account = create(:account_member)
      tag = Tag.create(tag_name: "Test Tag")

      expect { account.add_tag(tag) }.to change { account.tags.count }.by(1)
      expect(account.tags).to include(tag)
    end
  end

  describe "#remove_tag" do
    it "アカウントからタグを削除できること" do
      account = create(:account_member)
      tag = Tag.create(tag_name: "Test Tag")
      account.add_tag(tag)

      expect { account.remove_tag(tag) }.to change { account.tags.count }.by(-1)
      expect(account.tags).not_to include(tag)
    end
  end

  describe "#get_status" do
    before do
      @account = create(:account_member)
      @area = create(:area)
      @task = create(:task, area_id: @area.id)
      @cycle = create(:assign_cycle, task_id: @task.id)
    end

    it "アカウントのステータスを取得できること" do
      status = @account.get_status

      expect(status).to be_a(Hash)
      expect(status).to have_key(:id)
      expect(status).to have_key(:capacity)
      expect(status).to have_key(:name)
      expect(status).to have_key(:total)
      expect(status).to have_key(:week)
      expect(status).to have_key(:ng_rate)
      expect(status).to have_key(:assign)
    end

    it "完了したタスク数を正しくカウントすること" do
      create(:assign_history, account_id: @account.id, assign_cycle_id: @cycle.id, completed: true, completed_at: Time.now)
      create(:assign_history, account_id: @account.id, assign_cycle_id: @cycle.id, completed: true, completed_at: Time.now)

      status = @account.get_status

      expect(status[:total]).to eq(2)
    end

    it "未完了のアサイン数を正しくカウントすること" do
      create(:assign_history, account_id: @account.id, assign_cycle_id: @cycle.id, ng: false, completed: false)

      status = @account.get_status

      expect(status[:assign]).to eq(1)
    end

    it "NG率を正しく計算すること" do
      create(:assign_history, account_id: @account.id, assign_cycle_id: @cycle.id, completed: true, completed_at: Time.now)
      create(:assign_history, account_id: @account.id, assign_cycle_id: @cycle.id, ng: true)

      status = @account.get_status

      expect(status[:ng_rate]).to eq(1.0)
    end

    it "完了タスクが0の場合でもゼロ除算エラーが発生しないこと" do
      status = @account.get_status

      expect(status[:ng_rate]).to eq(0.0)
    end
  end

  describe ".get_role_one_status" do
    it "全てのメンバーのステータスを取得できること" do
      create_list(:account_member, 3)
      create(:account) # admin

      statuses = Account.get_role_one_status

      expect(statuses.length).to eq(3)
      statuses.each do |status|
        expect(status).to have_key(:id)
        expect(status).to have_key(:name)
      end
    end

    it "adminは含まれないこと" do
      create(:account_member)
      admin = create(:account)

      statuses = Account.get_role_one_status

      expect(statuses.length).to eq(1)
      expect(statuses.map { |s| s[:id] }).not_to include(admin.id)
    end
  end
end
