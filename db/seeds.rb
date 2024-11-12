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
# Initialize Function Access data

if FunctionAccess.all.blank?
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
      { code: "FA_ASS_COM_ASSET_TYPE", description: "Function access for Asset Type menu", active: true },
      { code: "FA_ASS_COM_ASSET_ITEM_TYPE", description: "Function access for Asset Item Type menu", active: true },
      { code: "FA_ASS_COM_ASSET_MODEL", description: "Function access for Asset Model menu", active: true },
      { code: "FA_ASS_REGISTER_USER_ASSET", description: "Function access for Register User Asset menu", active: true },
      { code: "FA_ASS_CP", description: "Function access for Capital Proposal menu", active: true },
      { code: "FA_ASS_RFP", description: "Function access for Request for Purchase menu", active: true },
      { code: "FA_ASS_PO", description: "Function access for Purchase Order menu", active: true },
      { code: "FA_ASS_DO", description: "Function access for Delivery Order menu", active: true },
      { code: "FA_LOC_SITE_DEFAULT", description: "Function access for Site Default menu", active: true },
      { code: "FA_ASSET", description: "Function access for Register Asset menu", active: true }
    ]
  )
end

RoutePath.create(
  [
    {
      function_access: FunctionAccess.find_by_code("FA_MST_SITE_STAT"),
      path: "admin_site_stats_path",
      parent: "entry",
      group: "master",
      index: true,
      sort: 3,
      label: "t('activerecord.models.site_stat')",
      description: "Route for Asset Status index"
    },
    {
      function_access: FunctionAccess.find_by_code("FA_MST_VENDOR"),
      path: "admin_vendors_path",
      parent: "entry",
      group: "master",
      index: true,
      sort: 2,
      label: "t('activerecord.models.site_stat')",
      description: "Route for Asset Status index"
    }
  ]
)
