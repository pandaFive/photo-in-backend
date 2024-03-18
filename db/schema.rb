# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_03_18_181220) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_areas", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "area_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_areas_on_account_id"
    t.index ["area_id"], name: "index_account_areas_on_area_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "capacity", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "areas", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "assign_cycles", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_assign_cycles_on_task_id"
  end

  create_table "assign_histories", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "assign_cycle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_assign_histories_on_account_id"
    t.index ["assign_cycle_id"], name: "index_assign_histories_on_assign_cycle_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "account_id", null: false
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_comments_on_account_id"
    t.index ["task_id"], name: "index_comments_on_task_id"
  end

  create_table "completed_tasks", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_completed_tasks_on_account_id"
    t.index ["task_id"], name: "index_completed_tasks_on_task_id"
  end

  create_table "ng_histories", force: :cascade do |t|
    t.bigint "assign_cycle_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ng_histories_on_account_id"
    t.index ["assign_cycle_id"], name: "index_ng_histories_on_assign_cycle_id"
  end

  create_table "tag_accounts", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_tag_accounts_on_account_id"
    t.index ["tag_id"], name: "index_tag_accounts_on_tag_id"
  end

  create_table "tag_tasks", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_tag_tasks_on_tag_id"
    t.index ["task_id"], name: "index_tag_tasks_on_task_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "area_id", null: false
    t.string "task_title", null: false
    t.boolean "is_complete", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_tasks_on_area_id"
  end

  add_foreign_key "account_areas", "accounts"
  add_foreign_key "account_areas", "areas"
  add_foreign_key "assign_cycles", "tasks"
  add_foreign_key "assign_histories", "accounts"
  add_foreign_key "assign_histories", "assign_cycles"
  add_foreign_key "comments", "accounts"
  add_foreign_key "comments", "tasks"
  add_foreign_key "completed_tasks", "accounts"
  add_foreign_key "completed_tasks", "tasks"
  add_foreign_key "ng_histories", "accounts"
  add_foreign_key "ng_histories", "assign_cycles"
  add_foreign_key "tag_accounts", "accounts"
  add_foreign_key "tag_accounts", "tags"
  add_foreign_key "tag_tasks", "tags"
  add_foreign_key "tag_tasks", "tasks"
  add_foreign_key "tasks", "areas"
end
