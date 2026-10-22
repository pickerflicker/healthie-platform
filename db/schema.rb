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

ActiveRecord::Schema[8.1].define(version: 2026_10_22_192000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "clients", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_clients_on_user_id", unique: true
  end

  create_table "enrollments", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "client_id", null: false
    t.string "plan", default: "basic", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_enrollments_on_client_id"
    t.index ["provider_id", "client_id"], name: "index_enrollments_on_provider_id_and_client_id", unique: true
    t.check_constraint "plan::text = ANY (ARRAY['basic'::character varying::text, 'premium'::character varying::text])", name: "enrollments_plan_valid"
  end

  create_table "journal_entries", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.text "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "provider_id"
    t.index ["client_id", "created_at", "id"], name: "index_journal_entries_on_client_id_and_created_at_and_id"
    t.index ["provider_id", "client_id", "created_at"], name: "index_journals_on_provider_client_month"
    t.index ["provider_id", "created_at", "id"], name: "index_journals_on_provider_feed"
  end

  create_table "providers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "credentials", default: [], null: false, array: true
    t.index ["user_id"], name: "index_providers_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.check_constraint "role::text = ANY (ARRAY['provider'::character varying::text, 'client'::character varying::text])", name: "users_role"
  end

  add_foreign_key "clients", "users"
  add_foreign_key "enrollments", "clients"
  add_foreign_key "enrollments", "providers"
  add_foreign_key "journal_entries", "clients"
  add_foreign_key "journal_entries", "providers"
  add_foreign_key "providers", "users"
end
