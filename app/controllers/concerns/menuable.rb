module Menuable
  extend ActiveSupport::Concern

  included do
    helper_method :has_entry_menu?
    helper_method :menu_masters
  end

  def has_entry_menu?
    return true if current_account.role.function_accesses.joins(:route_paths).where(route_paths: { parent: "entry" }).present?
    false
  end

  def menu_masters
    menu_masters ||= current_account.role.function_accesses.joins(:route_paths).where(route_paths: { group: "master" })
  end
end