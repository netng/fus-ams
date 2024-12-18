# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Current.account = Account.new(username: "system")

# Initialize default system data

# Function Access
  FunctionAccess.create(
    [
      { code: "FA_MST_SITE_STAT", description: "Function access for Asset Status menu", active: true },
      { code: "FA_MST_VENDOR", description: "Function access for Vendor menu", active: true },
      { code: "FA_MST_BRAND", description: "Function access for Brand menu", active: true },
      { code: "FA_MST_PROJECT", description: "Function access for Project menu", active: true },
      { code: "FA_LOC_DEPARTMENT", description: "Function access for Department menu", active: true },
      { code: "FA_LOC_SITE_GROUP", description: "Function access for Site Group menu", active: true },
      { code: "FA_LOC_SITE", description: "Function access for Site menu", active: true },
      { code: "FA_ASS_COM_SOFTWARE", description: "Function access for Software menu", active: true },
      { code: "FA_ASS_COM_COMPONENT_TYPE", description: "Function access for Component Type menu", active: true },
      { code: "FA_ASS_COM_COMPONENT", description: "Function access for Component menu", active: true },
      { code: "FA_ASS_COM_ASSET_TYPE", description: "Function access for Asset Type menu", active: true },
      { code: "FA_ASS_COM_ASSET_ITEM_TYPE", description: "Function access for Asset Item Type menu", active: true },
      { code: "FA_ASS_COM_ASSET_MODEL", description: "Function access for Asset Model menu", active: true },
      { code: "FA_ASS_REGISTER_USER_ASSET", description: "Function access for Register User Asset menu", active: true },
      { code: "FA_ASS_CP", description: "Function access for Capital Proposal menu", active: true },
      { code: "FA_ASS_RFP", description: "Function access for Request for Purchase menu", active: true },
      { code: "FA_ASS_PO", description: "Function access for Purchase Order menu", active: true },
      { code: "FA_ASS_DO", description: "Function access for Delivery Order menu", active: true },
      { code: "FA_ASS_INVENTORY_LOCACTION", description: "Function access for Asset inventory location menu", active: true },
      { code: "FA_LOC_SITE_DEFAULT", description: "Function access for Site Default menu", active: true },
      { code: "FA_ASSET", description: "Function access for Register Asset menu", active: true },
      { code: "FA_ROLE", description: "Function access for Role configuration menu", active: true },
      { code: "FA_ACCOUNT", description: "Function access for Account administration menu", active: true },
      { code: "FA_MST_ASS_SCHEDULE", description: "Function access for Asset schedule menu", active: true },
      { code: "FA_MST_STORAGE_UNIT", description: "Function access for Storage unit menu", active: true }
    ]
  )

# Role
role = Role.find_by_name("administrator")
if role.blank?
  role = Role.new(name: 'administrator', description: "Super administrator role", active: true)
end

# RoutePath
RoutePath.create(
  [
    # master
    {
      function_access: FunctionAccess.find_by_code("FA_MST_STORAGE_UNIT"),
      path: "admin_storage_units_path",
      parent: "entry",
      group: "master",
      index: true,
      sort: 5,
      label: "activerecord.models.storage_unit",
      description: "Route for storage_unit index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_ASS_SCHEDULE"),
      path: "admin_asset_schedules_path",
      parent: "entry",
      group: "master",
      index: true,
      sort: 4,
      label: "activerecord.models.asset_schedule",
      description: "Route for asset_schedule index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_SITE_STAT"),
      path: "admin_site_stats_path",
      parent: "entry",
      group: "master",
      index: true,
      sort: 3,
      label: "activerecord.models.site_stat",
      description: "Route for Asset Status index"
    },
    {
      function_access: FunctionAccess.find_by_code("FA_MST_VENDOR"),
      path: "admin_vendors_path",
      parent: "entry",
      group: "master",
      index: true,
      sort: 2,
      label: "activerecord.models.vendor",
      description: "Route for Asset Status index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_BRAND"),
      path: "admin_brands_path",
      parent: "entry",
      group: "master",
      index: true,
      sort: 1,
      label: "activerecord.models.brand",
      description: "Route for Brand index"
    },

    

    # location
    {
      function_access: FunctionAccess.find_by_code("FA_MST_PROJECT"),
      path: "admin_projects_path",
      parent: "entry",
      group: "location",
      index: true,
      sort: 1,
      label: "activerecord.models.project",
      description: "Route for project index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_LOC_SITE_GROUP"),
      path: "admin_site_groups_path",
      parent: "entry",
      group: "location",
      index: true,
      sort: 2,
      label: "activerecord.models.site_group",
      description: "Route for site_group index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_LOC_SITE"),
      path: "admin_sites_path",
      parent: "entry",
      group: "location",
      index: true,
      sort: 3,
      label: "activerecord.models.site",
      description: "Route for site index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_LOC_DEPARTMENT"),
      path: "admin_departments_path",
      parent: "entry",
      group: "location",
      index: true,
      sort: 4,
      label: "activerecord.models.department",
      description: "Route for department index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_LOC_SITE_DEFAULT"),
      path: "admin_site_defaults_path",
      parent: "entry",
      group: "location",
      index: true,
      sort: 5,
      label: "activerecord.models.site_default",
      description: "Route for site_default index"
    },

    # asset and component
    {
      function_access: FunctionAccess.find_by_code("FA_ASS_COM_ASSET_TYPE"),
      path: "admin_asset_types_path",
      parent: "entry",
      group: "asset_and_component",
      index: true,
      sort: 1,
      label: "activerecord.models.asset_type",
      description: "Route for asset_type index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_COM_ASSET_ITEM_TYPE"),
      path: "admin_asset_item_types_path",
      parent: "entry",
      group: "asset_and_component",
      index: true,
      sort: 2,
      label: "activerecord.models.asset_item_type",
      description: "Route for asset_item_type index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_COM_ASSET_MODEL"),
      path: "admin_asset_models_path",
      parent: "entry",
      group: "asset_and_component",
      index: true,
      sort: 3,
      label: "activerecord.models.asset_model",
      description: "Route for asset model index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_COM_COMPONENT_TYPE"),
      path: "admin_component_types_path",
      parent: "entry",
      group: "asset_and_component",
      index: true,
      sort: 4,
      label: "activerecord.models.component_type",
      description: "Route for component type index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_COM_COMPONENT"),
      path: "admin_components_path",
      parent: "entry",
      group: "asset_and_component",
      index: true,
      sort: 5,
      label: "activerecord.models.component",
      description: "Route for component index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_COM_SOFTWARE"),
      path: "admin_softwares_path",
      parent: "entry",
      group: "asset_and_component",
      index: true,
      sort: 6,
      label: "activerecord.models.software",
      description: "Route for software index"
    },

    # asset
    {
      function_access: FunctionAccess.find_by_code("FA_ASS_CP"),
      path: "admin_capital_proposals_path",
      parent: "entry",
      group: "asset",
      index: true,
      sort: 1,
      label: "activerecord.models.capital_proposal",
      description: "Route for capital proposal index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_RFP"),
      path: "admin_request_for_purchases_path",
      parent: "entry",
      group: "asset",
      index: true,
      sort: 2,
      label: "activerecord.models.request_for_purchase",
      description: "Route for request for purchase index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_PO"),
      path: "admin_purchase_orders_path",
      parent: "entry",
      group: "asset",
      index: true,
      sort: 3,
      label: "activerecord.models.purchase_order",
      description: "Route for purchase order index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_DO"),
      path: "admin_delivery_orders_path",
      parent: "entry",
      group: "asset",
      index: true,
      sort: 4,
      label: "activerecord.models.delivery_order",
      description: "Route for delivery order index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASSET"),
      path: "admin_assets_path",
      parent: "entry",
      group: "asset",
      index: true,
      sort: 5,
      label: "activerecord.models.asset",
      description: "Route for register asset index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_REGISTER_USER_ASSET"),
      path: "admin_user_assets_path",
      parent: "entry",
      group: "asset",
      index: true,
      sort: 6,
      label: "activerecord.models.user_asset",
      description: "Route for register user asset index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASS_INVENTORY_LOCATION"),
      path: "admin_user_assets_path",
      parent: "entry",
      group: "asset",
      index: true,
      sort: 7,
      label: "activerecord.models.user_asset",
      description: "Route for register user asset index"
    },

    # setup
    {
      function_access: FunctionAccess.find_by_code("FA_ACCOUNT"),
      path: "admin_accounts_path",
      parent: "setup",
      group: "account",
      index: true,
      sort: 1,
      label: "activerecord.models.account",
      description: "Route for login account management index"
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ROLE"),
      path: "admin_roles_path",
      parent: "setup",
      group: "role",
      index: true,
      sort: 2,
      label: "activerecord.models.role",
      description: "Route for login role management index"
    }

  ]
)

# Create Role function access for role: administrator
# Ambil semua function_access dan persiapkan data
data_to_upsert = FunctionAccess.all.map do |fa|
  {
    role_id: role.id,
    function_access_id: fa.id,
    allow_create: true,
    allow_read: true,
    allow_update: true,
    allow_delete: true,
    allow_confirm: true,
    allow_cancel_confirm: true,
    created_at: Time.current,
    updated_at: Time.current
  }
end

# Upsert data dalam satu query
RoleFunctionAccess.upsert_all(
  data_to_upsert,
  unique_by: [ :role_id, :function_access_id ]
)
