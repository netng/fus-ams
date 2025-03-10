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

ActiveRecord::Schema[8.0].define(version: 2025_01_14_031944) do
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
    t.boolean "default", default: false
    t.uuid "site_id", null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["role_id"], name: "index_accounts_on_role_id"
    t.index ["site_id"], name: "index_accounts_on_site_id"
    t.index ["username"], name: "index_accounts_on_username", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "asset_classes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "id_asset_class", limit: 100, null: false
    t.string "name", limit: 100, null: false
    t.uuid "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.index ["id_asset_class"], name: "index_asset_classes_on_id_asset_class", unique: true
    t.index ["project_id"], name: "index_asset_classes_on_project_id"
  end

  create_table "asset_components", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "asset_id"
    t.uuid "component_id"
    t.string "serial_number", limit: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.index ["asset_id"], name: "index_asset_components_on_asset_id"
    t.index ["component_id"], name: "index_asset_components_on_component_id"
    t.index ["serial_number"], name: "index_asset_components_on_serial_number"
  end

  create_table "asset_import_queues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "job_id", null: false
    t.string "error_messages"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.decimal "execution_time", precision: 5, scale: 2
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_asset_import_queues_on_job_id", unique: true
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
    t.string "id_asset_item_type", null: false
    t.index ["asset_type_id"], name: "index_asset_item_types_on_asset_type_id"
    t.index ["id_asset_item_type"], name: "index_asset_item_types_on_id_asset_item_type", unique: true
    t.index ["name"], name: "index_asset_item_types_on_name"
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
    t.string "id_asset_model", null: false
    t.index ["asset_item_type_id"], name: "index_asset_models_on_asset_item_type_id"
    t.index ["asset_type_id"], name: "index_asset_models_on_asset_type_id"
    t.index ["brand_id"], name: "index_asset_models_on_brand_id"
    t.index ["id_asset_model"], name: "index_asset_models_on_id_asset_model", unique: true
    t.index ["name"], name: "index_asset_models_on_name"
  end

  create_table "asset_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "description", limit: 500
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.index ["name"], name: "index_asset_schedules_on_name", unique: true
  end

  create_table "asset_softwares", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "asset_id", null: false
    t.uuid "software_id", null: false
    t.string "license"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sequence_number", null: false
    t.index ["asset_id", "software_id"], name: "index_asset_softwares_on_asset_id_and_software_id", unique: true
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
    t.string "id_asset_type", null: false
    t.index ["id_asset_type"], name: "index_asset_types_on_id_asset_type", unique: true
    t.index ["name"], name: "index_asset_types_on_name"
  end

  create_table "assets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "tagging_date", null: false
    t.string "tagging_id", limit: 100, null: false
    t.uuid "project_id", null: false
    t.uuid "site_id", null: false
    t.uuid "asset_model_id", null: false
    t.uuid "user_asset_id", null: false
    t.uuid "delivery_order_id"
    t.string "computer_name", limit: 100
    t.string "computer_ip", limit: 100
    t.string "cpu_sn", limit: 100
    t.string "monitor_sn", limit: 100
    t.string "keyboard_sn", limit: 100
    t.datetime "shipping_date"
    t.string "description", limit: 500
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "asset_class_id"
    t.string "schedule", limit: 100
    t.uuid "asset_schedule_id"
    t.uuid "rooms_storage_units_bin_id"
    t.index ["asset_class_id"], name: "index_assets_on_asset_class_id"
    t.index ["asset_model_id"], name: "index_assets_on_asset_model_id"
    t.index ["asset_schedule_id"], name: "index_assets_on_asset_schedule_id"
    t.index ["delivery_order_id"], name: "index_assets_on_delivery_order_id"
    t.index ["project_id"], name: "index_assets_on_project_id"
    t.index ["rooms_storage_units_bin_id"], name: "index_assets_on_rooms_storage_units_bin_id"
    t.index ["site_id"], name: "index_assets_on_site_id"
    t.index ["tagging_id"], name: "index_assets_on_tagging_id", unique: true
    t.index ["user_asset_id"], name: "index_assets_on_user_asset_id"
  end

  create_table "assets_inventory_locations_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "asset_id", null: false
    t.uuid "inventory_locations_detail_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id", "inventory_locations_detail_id"], name: "idx_on_asset_id_inventory_locations_detail_id_ae93c1387b", unique: true
    t.index ["asset_id"], name: "index_assets_inventory_locations_details_on_asset_id"
    t.index ["inventory_locations_detail_id"], name: "idx_on_inventory_locations_detail_id_75cdb5f61d"
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

  create_table "capital_proposal_group_headers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "id_capital_proposal_group_header", limit: 100, null: false
    t.string "name", limit: 100
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id_capital_proposal_group_header"], name: "idx_on_id_capital_proposal_group_header_5f91f718d8", unique: true
  end

  create_table "capital_proposal_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "id_capital_proposal_group", limit: 100, null: false
    t.string "name", limit: 100
    t.uuid "capital_proposal_group_header_id", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["capital_proposal_group_header_id"], name: "idx_on_capital_proposal_group_header_id_2321905d54"
    t.index ["id_capital_proposal_group"], name: "index_capital_proposal_groups_on_id_capital_proposal_group", unique: true
  end

  create_table "capital_proposal_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "id_capital_proposal_type", limit: 100, null: false
    t.string "name", limit: 100
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id_capital_proposal_type"], name: "index_capital_proposal_types_on_id_capital_proposal_type", unique: true
  end

  create_table "capital_proposals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "number", limit: 100, null: false
    t.string "real_number", limit: 100
    t.uuid "capital_proposal_type_id", null: false
    t.uuid "capital_proposal_group_id", null: false
    t.uuid "site_id", null: false
    t.uuid "department_id", null: false
    t.datetime "date", null: false
    t.string "description", null: false
    t.decimal "equiv_amount", precision: 18, scale: 2, null: false
    t.decimal "rate", precision: 18, scale: 2, null: false
    t.decimal "amount", precision: 18, scale: 2, null: false
    t.string "status", limit: 100, null: false
    t.string "budget_ref_number", limit: 100, null: false
    t.decimal "budget_amount", precision: 18, scale: 2, null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "currency_id", null: false
    t.index ["capital_proposal_group_id"], name: "index_capital_proposals_on_capital_proposal_group_id"
    t.index ["capital_proposal_type_id"], name: "index_capital_proposals_on_capital_proposal_type_id"
    t.index ["currency_id"], name: "index_capital_proposals_on_currency_id"
    t.index ["department_id"], name: "index_capital_proposals_on_department_id"
    t.index ["number"], name: "index_capital_proposals_on_number", unique: true
    t.index ["site_id"], name: "index_capital_proposals_on_site_id"
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
    t.string "id_component_type", null: false
    t.index ["id_component_type"], name: "index_component_types_on_id_component_type", unique: true
    t.index ["name"], name: "index_component_types_on_name"
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
    t.string "id_component", null: false
    t.index ["component_type_id"], name: "index_components_on_component_type_id"
    t.index ["id_component"], name: "index_components_on_id_component", unique: true
    t.index ["name"], name: "index_components_on_name"
  end

  create_table "currencies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "id_currency", null: false
    t.string "name", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id_currency"], name: "index_currencies_on_id_currency", unique: true
  end

  create_table "delivery_orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "number", limit: 100, null: false
    t.datetime "date", null: false
    t.uuid "purchase_order_id"
    t.datetime "warranty_expired"
    t.string "description", limit: 500
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "schedule", limit: 100
    t.index ["number"], name: "index_delivery_orders_on_number", unique: true
    t.index ["purchase_order_id"], name: "index_delivery_orders_on_purchase_order_id"
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

  create_table "inventories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "site_id", null: false
    t.uuid "asset_id", null: false
    t.uuid "rooms_storage_units_bin_id", null: false
    t.string "status", default: "IN_STOCK"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_inventories_on_asset_id"
    t.index ["rooms_storage_units_bin_id"], name: "index_inventories_on_rooms_storage_units_bin_id"
    t.index ["site_id", "asset_id"], name: "index_inventories_on_site_id_and_asset_id", unique: true
    t.index ["site_id"], name: "index_inventories_on_site_id"
  end

  create_table "inventory_locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "floor", limit: 100, null: false
    t.uuid "site_id", null: false
    t.string "description", limit: 500
    t.boolean "active"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rooms_count", default: 0
    t.index ["floor", "site_id"], name: "index_inventory_locations_on_floor_and_site_id", unique: true
    t.index ["site_id"], name: "index_inventory_locations_on_site_id"
  end

  create_table "inventory_locations_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "inventory_location_id", null: false
    t.uuid "storage_unit_id", null: false
    t.string "label", limit: 100, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_location_id"], name: "index_inventory_locations_details_on_inventory_location_id"
    t.index ["storage_unit_id", "label"], name: "index_inventory_locations_details_on_storage_unit_id_and_label", unique: true
    t.index ["storage_unit_id"], name: "index_inventory_locations_details_on_storage_unit_id"
  end

  create_table "inventory_movement_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "inventory_movement_id", null: false
    t.uuid "inventory_id", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_id"], name: "index_inventory_movement_details_on_inventory_id"
    t.index ["inventory_movement_id"], name: "index_inventory_movement_details_on_inventory_movement_id"
  end

  create_table "inventory_movements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "id_inventory_movement", limit: 100, null: false
    t.string "movement_type", limit: 100, null: false
    t.uuid "source_site_id", null: false
    t.uuid "destination_site_id"
    t.uuid "user_asset_id"
    t.integer "quantity", default: 0
    t.string "status", default: "IN_PROGRESS"
    t.string "description", limit: 500
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_site_id"], name: "index_inventory_movements_on_destination_site_id"
    t.index ["id_inventory_movement"], name: "index_inventory_movements_on_id_inventory_movement", unique: true
    t.index ["source_site_id"], name: "index_inventory_movements_on_source_site_id"
    t.index ["user_asset_id"], name: "index_inventory_movements_on_user_asset_id"
  end

  create_table "personal_boards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "id_personal_board", limit: 100, null: false
    t.string "username", limit: 100, null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id_personal_board"], name: "index_personal_boards_on_id_personal_board", unique: true
  end

  create_table "po_delivery_sites", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "id_po_delivery_site", limit: 100, null: false
    t.string "name", limit: 100
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id_po_delivery_site"], name: "index_po_delivery_sites_on_id_po_delivery_site", unique: true
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

  create_table "purchase_orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "number", limit: 100, null: false
    t.datetime "date", null: false
    t.uuid "vendor_id", null: false
    t.uuid "request_for_purchase_id", null: false
    t.datetime "delivery_date", null: false
    t.string "payment_remarks", limit: 100
    t.string "description", limit: 500
    t.string "status", null: false
    t.uuid "currency_id"
    t.decimal "amount_by_currency", precision: 18, scale: 2
    t.decimal "rate", precision: 18, scale: 2
    t.decimal "amount_by_rate", precision: 18, scale: 2
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "approved_by_id", null: false
    t.uuid "ship_to_site_id", null: false
    t.index ["approved_by_id"], name: "index_purchase_orders_on_approved_by_id"
    t.index ["currency_id"], name: "index_purchase_orders_on_currency_id"
    t.index ["number"], name: "index_purchase_orders_on_number", unique: true
    t.index ["request_for_purchase_id"], name: "index_purchase_orders_on_request_for_purchase_id"
    t.index ["ship_to_site_id"], name: "index_purchase_orders_on_ship_to_site_id"
    t.index ["vendor_id"], name: "index_purchase_orders_on_vendor_id"
  end

  create_table "report_queues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "file_path", null: false
    t.uuid "generated_by_id", null: false
    t.integer "download_count", default: 0
    t.string "last_downloaded_by", limit: 100
    t.datetime "last_downloaded_at"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "job_id", null: false
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.decimal "execution_time", precision: 5, scale: 2
    t.integer "data_count", default: 0
    t.boolean "status"
    t.index ["generated_by_id"], name: "index_report_queues_on_generated_by_id"
  end

  create_table "request_for_purchase_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "qty"
    t.datetime "tentative_date"
    t.datetime "confirm_date"
    t.string "specs", limit: 500
    t.uuid "currency_id"
    t.decimal "rate", precision: 18, scale: 2
    t.uuid "request_for_purchase_id"
    t.decimal "price", precision: 18, scale: 2
    t.decimal "sub_total", precision: 18, scale: 2
    t.string "status", limit: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "purchase_order_id"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.index ["currency_id"], name: "index_request_for_purchase_details_on_currency_id"
    t.index ["purchase_order_id"], name: "index_request_for_purchase_details_on_purchase_order_id"
    t.index ["request_for_purchase_id"], name: "index_request_for_purchase_details_on_request_for_purchase_id"
  end

  create_table "request_for_purchases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "number", limit: 100, null: false
    t.uuid "capital_proposal_id"
    t.uuid "from_department_id", null: false
    t.uuid "to_department_id", null: false
    t.datetime "date", null: false
    t.string "material_code", limit: 100, null: false
    t.string "remarks", limit: 100
    t.string "issued_by", limit: 100
    t.string "authorized_by", limit: 100
    t.string "status", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["capital_proposal_id"], name: "index_request_for_purchases_on_capital_proposal_id"
    t.index ["from_department_id"], name: "index_request_for_purchases_on_from_department_id"
    t.index ["number"], name: "index_request_for_purchases_on_number", unique: true
    t.index ["to_department_id"], name: "index_request_for_purchases_on_to_department_id"
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
    t.boolean "default", default: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "rooms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "description", limit: 500
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "inventory_location_id", null: false
    t.integer "rooms_storage_units_count", default: 0
    t.index ["inventory_location_id"], name: "index_rooms_on_inventory_location_id"
    t.index ["name", "inventory_location_id"], name: "index_rooms_on_name_and_inventory_location_id", unique: true
  end

  create_table "rooms_storage_units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "room_id", null: false
    t.uuid "storage_unit_id", null: false
    t.string "label", limit: 100, null: false
    t.string "capacity", limit: 100
    t.string "description", limit: 500
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label", "room_id", "storage_unit_id"], name: "idx_on_label_room_id_storage_unit_id_10022de3c0", unique: true
    t.index ["room_id"], name: "index_rooms_storage_units_on_room_id"
    t.index ["storage_unit_id"], name: "index_rooms_storage_units_on_storage_unit_id"
  end

  create_table "rooms_storage_units_bins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "rooms_storage_unit_id", null: false
    t.string "label", limit: 100, null: false
    t.string "description", limit: 500
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label", "rooms_storage_unit_id"], name: "idx_on_label_rooms_storage_unit_id_fdfa0f7385", unique: true
    t.index ["rooms_storage_unit_id"], name: "index_rooms_storage_units_bins_on_rooms_storage_unit_id"
  end

  create_table "route_paths", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "function_access_id", null: false
    t.string "path", limit: 100, null: false
    t.string "label", limit: 100, null: false
    t.string "description", limit: 500
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "group", limit: 100
    t.integer "sort", default: 0
    t.boolean "index", default: false
    t.string "parent", limit: 100
    t.boolean "active", default: true
    t.index ["function_access_id"], name: "index_route_paths_on_function_access_id"
    t.index ["path"], name: "index_route_paths_on_path", unique: true
  end

  create_table "site_defaults", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "site_id", null: false
    t.string "name"
    t.string "id_user_site_default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.string "description", limit: 500
    t.index ["id_user_site_default"], name: "index_site_defaults_on_id_user_site_default"
    t.index ["site_id"], name: "index_site_defaults_on_site_id", unique: true
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
    t.uuid "parent_site_id"
    t.index ["id_site"], name: "index_sites_on_id_site", unique: true
    t.index ["name"], name: "index_sites_on_name"
    t.index ["parent_site_id"], name: "index_sites_on_parent_site_id"
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

  create_table "storage_units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "description", limit: 500
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_storage_units_on_name", unique: true
  end

  create_table "user_assets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "id_user_asset", null: false
    t.string "aztec_code"
    t.string "username"
    t.string "email"
    t.uuid "site_id", null: false
    t.uuid "department_id"
    t.string "location"
    t.string "floor"
    t.string "description"
    t.string "created_by"
    t.string "request_id"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assets_count", default: 0, null: false
    t.index ["department_id"], name: "index_user_assets_on_department_id"
    t.index ["id_user_asset"], name: "index_user_assets_on_id_user_asset", unique: true
    t.index ["site_id"], name: "index_user_assets_on_site_id"
    t.index ["username", "aztec_code"], name: "index_user_assets_on_username_and_aztec_code"
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
  add_foreign_key "accounts", "sites"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "asset_classes", "projects"
  add_foreign_key "asset_components", "assets"
  add_foreign_key "asset_components", "components"
  add_foreign_key "asset_item_types", "asset_types"
  add_foreign_key "asset_models", "asset_item_types"
  add_foreign_key "asset_models", "asset_types"
  add_foreign_key "asset_models", "brands"
  add_foreign_key "asset_softwares", "assets"
  add_foreign_key "asset_softwares", "softwares"
  add_foreign_key "assets", "asset_classes"
  add_foreign_key "assets", "asset_models"
  add_foreign_key "assets", "asset_schedules"
  add_foreign_key "assets", "delivery_orders"
  add_foreign_key "assets", "projects"
  add_foreign_key "assets", "rooms_storage_units_bins"
  add_foreign_key "assets", "sites"
  add_foreign_key "assets", "user_assets"
  add_foreign_key "assets_inventory_locations_details", "assets"
  add_foreign_key "assets_inventory_locations_details", "inventory_locations_details"
  add_foreign_key "capital_proposal_groups", "capital_proposal_group_headers"
  add_foreign_key "capital_proposals", "capital_proposal_groups"
  add_foreign_key "capital_proposals", "capital_proposal_types"
  add_foreign_key "capital_proposals", "currencies"
  add_foreign_key "capital_proposals", "departments"
  add_foreign_key "capital_proposals", "sites"
  add_foreign_key "components", "component_types"
  add_foreign_key "delivery_orders", "purchase_orders"
  add_foreign_key "inventories", "assets"
  add_foreign_key "inventories", "rooms_storage_units_bins"
  add_foreign_key "inventories", "sites"
  add_foreign_key "inventory_locations", "sites"
  add_foreign_key "inventory_locations_details", "inventory_locations"
  add_foreign_key "inventory_locations_details", "storage_units"
  add_foreign_key "inventory_movement_details", "inventories"
  add_foreign_key "inventory_movement_details", "inventory_movements"
  add_foreign_key "inventory_movements", "sites", column: "destination_site_id"
  add_foreign_key "inventory_movements", "sites", column: "source_site_id"
  add_foreign_key "inventory_movements", "user_assets"
  add_foreign_key "purchase_orders", "currencies"
  add_foreign_key "purchase_orders", "personal_boards", column: "approved_by_id"
  add_foreign_key "purchase_orders", "po_delivery_sites", column: "ship_to_site_id"
  add_foreign_key "purchase_orders", "request_for_purchases"
  add_foreign_key "purchase_orders", "vendors"
  add_foreign_key "report_queues", "accounts", column: "generated_by_id"
  add_foreign_key "request_for_purchase_details", "currencies"
  add_foreign_key "request_for_purchase_details", "purchase_orders"
  add_foreign_key "request_for_purchase_details", "request_for_purchases"
  add_foreign_key "request_for_purchases", "capital_proposals"
  add_foreign_key "request_for_purchases", "departments", column: "from_department_id"
  add_foreign_key "request_for_purchases", "departments", column: "to_department_id"
  add_foreign_key "role_function_accesses", "function_accesses"
  add_foreign_key "role_function_accesses", "roles"
  add_foreign_key "rooms", "inventory_locations"
  add_foreign_key "rooms_storage_units", "rooms"
  add_foreign_key "rooms_storage_units", "storage_units"
  add_foreign_key "rooms_storage_units_bins", "rooms_storage_units"
  add_foreign_key "route_paths", "function_accesses"
  add_foreign_key "site_defaults", "sites"
  add_foreign_key "site_groups", "projects"
  add_foreign_key "sites", "site_groups"
  add_foreign_key "sites", "site_stats"
  add_foreign_key "sites", "sites", column: "parent_site_id"
  add_foreign_key "user_assets", "departments"
  add_foreign_key "user_assets", "sites"
end
