module Admin::Entries
  class EntriesController < ApplicationAdminController
    def index
      skip_authorization
      # @entry_menus ||= current_account.role.function_accesses.joins(:route_paths).where(route_paths: { parent: "entry" })

      # @menu_masters ||= current_account.role.function_accesses.joins(:route_paths).where(route_paths: { group: "master" })
    end
  end
end
