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

ActiveRecord::Schema[8.0].define(version: 2024_10_16_075422) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "username", null: false
    t.string "password_digest", null: false
    t.datetime "confirmed_at"
    t.boolean "active", default: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "email", null: false
    t.uuid "role_id", null: false
    t.boolean "default"
    t.index ["role_id"], name: "index_accounts_on_role_id"
    t.index ["username"], name: "index_accounts_on_username", unique: true
  end

  create_table "asset_item_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "asset_type_id", null: false
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_type_id"], name: "index_asset_item_types_on_asset_type_id"
    t.index ["name"], name: "index_asset_item_types_on_name", unique: true
  end

  create_table "asset_models", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "brand_id", null: false
    t.uuid "asset_type_id", null: false
    t.uuid "asset_item_type_id", null: false
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_item_type_id"], name: "index_asset_models_on_asset_item_type_id"
    t.index ["asset_type_id"], name: "index_asset_models_on_asset_type_id"
    t.index ["brand_id"], name: "index_asset_models_on_brand_id"
    t.index ["name"], name: "index_asset_models_on_name", unique: true
  end

  create_table "asset_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_asset_types_on_name", unique: true
  end

  create_table "brands", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.string "id_brand"
    t.index ["id_brand"], name: "index_brands_on_id_brand", unique: true
    t.index ["name"], name: "index_brands_on_name"
  end

  create_table "component_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_component_types_on_name", unique: true
  end

  create_table "components", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "component_type_id", null: false
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["component_type_id"], name: "index_components_on_component_type_id"
    t.index ["name"], name: "index_components_on_name", unique: true
  end

  create_table "departments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "floor"
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_department", null: false
    t.index ["id_department"], name: "index_departments_on_id_department", unique: true
    t.index ["name"], name: "index_departments_on_name"
  end

  create_table "function_accesses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "label", null: false
    t.string "path", null: false
    t.string "description"
    t.boolean "admin", default: false
    t.boolean "active", default: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_function_accesses_on_code", unique: true
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_project", null: false
    t.index ["id_project"], name: "index_projects_on_id_project", unique: true
    t.index ["name"], name: "index_projects_on_name"
  end

  create_table "role_function_accesses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "role_id", null: false
    t.uuid "function_access_id", null: false
    t.boolean "allow_create", default: false
    t.boolean "allow_read", default: false
    t.boolean "allow_update", default: false
    t.boolean "allow_delete", default: false
    t.boolean "allow_confirm", default: false
    t.boolean "allow_cancel_confirm", default: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["function_access_id"], name: "index_role_function_accesses_on_function_access_id"
    t.index ["role_id", "function_access_id"], name: "index_role_function_accesses_on_role_id_and_function_access_id", unique: true
    t.index ["role_id"], name: "index_role_function_accesses_on_role_id"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.boolean "active", default: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "site_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.uuid "project_id", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_site_group", null: false
    t.index ["id_site_group"], name: "index_site_groups_on_id_site_group", unique: true
    t.index ["name"], name: "index_site_groups_on_name"
    t.index ["project_id"], name: "index_site_groups_on_project_id"
  end

  create_table "site_stats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_site_stat"
    t.index ["id_site_stat"], name: "index_site_stats_on_id_site_stat", unique: true
    t.index ["name"], name: "index_site_stats_on_name", unique: true
  end

  create_table "sites", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "site_stat_id", null: false
    t.uuid "site_group_id", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.string "id_site", null: false
    t.index ["id_site"], name: "index_sites_on_id_site", unique: true
    t.index ["name"], name: "index_sites_on_name"
    t.index ["site_group_id"], name: "index_sites_on_site_group_id"
    t.index ["site_stat_id"], name: "index_sites_on_site_stat_id"
  end

  create_table "softwares", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_software", null: false
    t.index ["id_software"], name: "index_softwares_on_id_software", unique: true
    t.index ["name"], name: "index_softwares_on_name"
  end

  create_table "vendors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "address1"
    t.text "address2"
    t.string "city"
    t.string "postal_code"
    t.string "phone_number"
    t.string "fax_number"
    t.string "contact_person"
    t.string "email"
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_vendor"
    t.index ["id_vendor"], name: "index_vendors_on_id_vendor", unique: true
    t.index ["name"], name: "index_vendors_on_name"
    t.index ["phone_number", "fax_number", "contact_person", "email"], name: "idx_on_phone_number_fax_number_contact_person_email_34185d41f8"
  end

  add_foreign_key "accounts", "roles"
  add_foreign_key "asset_item_types", "asset_types"
  add_foreign_key "asset_models", "asset_item_types"
  add_foreign_key "asset_models", "asset_types"
  add_foreign_key "asset_models", "brands"
  add_foreign_key "components", "component_types"
  add_foreign_key "role_function_accesses", "function_accesses"
  add_foreign_key "role_function_accesses", "roles"
  add_foreign_key "site_groups", "projects"
  add_foreign_key "sites", "site_groups"
  add_foreign_key "sites", "site_stats"
end
