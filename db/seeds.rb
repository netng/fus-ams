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

  # FUNCTION ACCESSES
  FunctionAccess.create(
    [
      # MASTERS
      { code: "FA_MST_BRAND", description: "Function access for Brand menu", active: true },
      { code: "FA_MST_VENDOR", description: "Function access for Vendor menu", active: true },
      { code: "FA_MST_SITE_STAT", description: "Function access for Asset Status menu", active: true },
      { code: "FA_MST_ASS_SCHEDULE", description: "Function access for Asset schedule menu", active: true },
      { code: "FA_MST_STORAGE_UNIT", description: "Function access for Storage unit menu", active: true },
      { code: "FA_MST_PROJECT", description: "Function access for Project menu", active: true },
      { code: "FA_MST_DEPARTMENT", description: "Function access for Department menu", active: true },
      { code: "FA_MST_ASSET_TYPE", description: "Function access for Asset Type menu", active: true },
      { code: "FA_MST_COMPONENT_TYPE", description: "Function access for Component Type menu", active: true },
      { code: "FA_MST_SOFTWARE", description: "Function access for Software menu", active: true },

      # SETTINGS
      { code: "FA_SET_SITE_GROUP", description: "Function access for Site Group menu", active: true },
      { code: "FA_SET_SITE", description: "Function access for Site menu", active: true },
      { code: "FA_SET_SITE_DEFAULT", description: "Function access for Site Default menu", active: true },
      { code: "FA_SET_ASSET_ITEM_TYPE", description: "Function access for Asset Item Type menu", active: true },
      { code: "FA_SET_ASSET_MODEL", description: "Function access for Asset Model menu", active: true },
      { code: "FA_SET_COMPONENT", description: "Function access for Component menu", active: true },

      # PROCUREMENTS
      { code: "FA_PROC_CP", description: "Function access for Capital Proposal menu", active: true },
      { code: "FA_PROC_RFP", description: "Function access for Request for Purchase menu", active: true },
      { code: "FA_PROC_PO", description: "Function access for Purchase Order menu", active: true },
      { code: "FA_PROC_DO", description: "Function access for Delivery Order menu", active: true },

      # INVENTORY MANAGEMENT
      { code: "FA_INVMGMT_DATA_INVENTORY", description: "Function access for Data Inventory menu", active: true },
      { code: "FA_INVMGMT_INVENTORY_LOCACTION", description: "Function access for Inventory Location menu", active: true },

      # ASSET MANAGEMENT
      { code: "FA_ASSMGMT_DATA_ASSET", description: "Function access for Data Asset menu", active: true },
      { code: "FA_ASSMGMT_USER_ASSET", description: "Function access for User Asset menu", active: true },
      { code: "FA_ASSMGMT_ASSET_LOCATION", description: "Function access for Asset Location menu", active: true },
      # { code: "FA_ASSMGMT_ASSET_SOFTWARE", description: "Function access for Asset Sofrware menu", active: true },

      # ACCESS MANAGEMENT
      { code: "FA_ACCMGMT_ROLE", description: "Function access for Role configuration menu", active: true },
      { code: "FA_ACCMGMT_ACCOUNT", description: "Function access for Account administration menu", active: true }
    ]
  )

# Role
role = Role.find_by_name("administrator")
if role.blank?
  role = Role.create(name: 'administrator', description: "Super administrator role", active: true)
end

# Default site stat
site_stat = SiteStat.find_by_id_site_stat("default")
if site_stat.blank?
  site_stat = SiteStat.create(name: "default", id_site_stat: "default")
end

# Default project
project = Project.find_by_name("default")
if project.blank?
  project = Project.create(name: "default", id_project: "default")
end

# Default site group
site_group = SiteGroup.find_by_id_site_group("default")
if site_group.blank?
  site_group = SiteGroup.create(name: "default", id_site_group: "default", project: project)
end

# Default site
site = Site.find_by_name("default")
if site.blank?
  site = Site.create(name: "default", site_stat: site_stat, site_group: site_group, id_site: "default")
end

# RoutePath
RoutePath.create(
  [
    # MASTERS
    {
      function_access: FunctionAccess.find_by_code("FA_MST_SOFTWARE"),
      path: "admin_softwares_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 10,
      label: "activerecord.models.software",
      description: "Route for software index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_COMPONENT_TYPE"),
      path: "admin_component_types_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 9,
      label: "activerecord.models.component_type",
      description: "Route for component type index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_ASSET_TYPE"),
      path: "admin_asset_types_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 8,
      label: "activerecord.models.asset_type",
      description: "Route for asset_type index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_DEPARTMENT"),
      path: "admin_departments_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 7,
      label: "activerecord.models.department",
      description: "Route for department index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_PROJECT"),
      path: "admin_projects_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 6,
      label: "activerecord.models.project",
      description: "Route for project index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_STORAGE_UNIT"),
      path: "admin_storage_units_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 5,
      label: "activerecord.models.storage_unit",
      description: "Route for storage_unit index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_ASS_SCHEDULE"),
      path: "admin_asset_schedules_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 4,
      label: "activerecord.models.asset_schedule",
      description: "Route for asset_schedule index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_SITE_STAT"),
      path: "admin_site_stats_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 3,
      label: "activerecord.models.site_stat",
      description: "Route for Asset Status index",
      active: true
    },
    {
      function_access: FunctionAccess.find_by_code("FA_MST_VENDOR"),
      path: "admin_vendors_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 2,
      label: "activerecord.models.vendor",
      description: "Route for Asset Status index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_MST_BRAND"),
      path: "admin_brands_path",
      parent: "masters",
      group: "",
      index: true,
      sort: 1,
      label: "activerecord.models.brand",
      description: "Route for Brand index",
      active: true
    },


    # SETTINGS
    {
      function_access: FunctionAccess.find_by_code("FA_SET_COMPONENT"),
      path: "admin_components_path",
      parent: "settings",
      group: "",
      index: true,
      sort: 6,
      label: "activerecord.models.component",
      description: "Route for component index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_SET_ASSET_MODEL"),
      path: "admin_asset_models_path",
      parent: "settings",
      group: "",
      index: true,
      sort: 5,
      label: "activerecord.models.asset_model",
      description: "Route for asset model index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_SET_ASSET_ITEM_TYPE"),
      path: "admin_asset_item_types_path",
      parent: "settings",
      group: "",
      index: true,
      sort: 4,
      label: "activerecord.models.asset_item_type",
      description: "Route for asset_item_type index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_SET_SITE_DEFAULT"),
      path: "admin_site_defaults_path",
      parent: "settings",
      group: "",
      index: true,
      sort: 3,
      label: "activerecord.models.site_default",
      description: "Route for site_default index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_SET_SITE"),
      path: "admin_sites_path",
      parent: "settings",
      group: "",
      index: true,
      sort: 2,
      label: "activerecord.models.site",
      description: "Route for site index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_SET_SITE_GROUP"),
      path: "admin_site_groups_path",
      parent: "settings",
      group: "",
      index: true,
      sort: 1,
      label: "activerecord.models.site_group",
      description: "Route for site_group index",
      active: true
    },

    # FINANCE MANAGEMENT
    {
      function_access: FunctionAccess.find_by_code("FA_PROC_DO"),
      path: "admin_delivery_orders_path",
      parent: "`procurements`",
      group: "",
      index: true,
      sort: 4,
      label: "activerecord.models.delivery_order",
      description: "Route for delivery order index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_PROC_PO"),
      path: "admin_purchase_orders_path",
      parent: "`procurements`",
      group: "",
      index: true,
      sort: 3,
      label: "activerecord.models.purchase_order",
      description: "Route for purchase order index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_PROC_RFP"),
      path: "admin_request_for_purchases_path",
      parent: "`procurements`",
      group: "",
      index: true,
      sort: 2,
      label: "activerecord.models.request_for_purchase",
      description: "Route for request for purchase index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_PROC_CP"),
      path: "admin_capital_proposals_path",
      parent: "`procurements`",
      group: "",
      index: true,
      sort: 1,
      label: "activerecord.models.capital_proposal",
      description: "Route for capital proposal index",
      active: true
    },


    # INVENTORY MANAGEMENT
    {
      function_access: FunctionAccess.find_by_code("FA_INVMGMT_INVENTORY_LOCACTION"),
      path: "admin_inventory_locations_path",
      parent: "inventory_management",
      group: "",
      index: true,
      sort: 2,
      label: "activerecord.models.inventory_location",
      description: "Route for register inventory location index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_INVMGMT_DATA_INVENTORY"),
      path: "admin_inventories_path",
      parent: "inventory_management",
      group: "",
      index: true,
      sort: 1,
      label: "activerecord.models.inventory",
      description: "Route for data inventory index",
      active: true
    },

    # ASSET MANAGEMENT
    # {
    #   function_access: FunctionAccess.find_by_code("FA_ASSMGMT_ASSET_SOFTWARE"),
    #   path: "admin_asset_softwares_path",
    #   parent: "asset_management",
    #   group: "",
    #   index: true,
    #   sort: 4,
    #   label: "activerecord.models.asset_software",
    #   description: "Route for asset software index",
    #   active: true
    # },

    {
      function_access: FunctionAccess.find_by_code("FA_ASSMGMT_ASSET_LOCATION"),
      path: "admin_asset_locations_path",
      parent: "asset_management",
      group: "",
      index: true,
      sort: 3,
      label: "custom.label.asset_location",
      description: "Route for asset location index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASSMGMT_USER_ASSET"),
      path: "admin_user_assets_path",
      parent: "asset_management",
      group: "",
      index: true,
      sort: 2,
      label: "activerecord.models.user_asset",
      description: "Route for user asset index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ASSMGMT_DATA_ASSET"),
      path: "admin_assets_path",
      parent: "asset_management",
      group: "",
      index: true,
      sort: 1,
      label: "activerecord.models.asset",
      description: "Route for data asset index",
      active: true
    },

    # ACCESS MANAGEMENT
    {
      function_access: FunctionAccess.find_by_code("FA_ACCMGMT_ROLE"),
      path: "admin_roles_path",
      parent: "access_management",
      group: "",
      index: true,
      sort: 2,
      label: "activerecord.models.role",
      description: "Route for login role management index",
      active: true
    },

    {
      function_access: FunctionAccess.find_by_code("FA_ACCMGMT_ACCOUNT"),
      path: "admin_accounts_path",
      parent: "access_management",
      group: "",
      index: true,
      sort: 1,
      label: "activerecord.models.account",
      description: "Route for login account management index",
      active: true
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
