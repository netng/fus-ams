module Menuable
  extend ActiveSupport::Concern

  included do
    helper_method :has_entry_menu?
    helper_method :has_setup_menu?

    helper_method :menu_masters
    helper_method :menu_locations
    helper_method :menu_accounts
    helper_method :menu_roles
    helper_method :menu_asset_components
    helper_method :menu_assets
  end

  def has_entry_menu?
    return true if has_active_role? && has_parent_menu?("entry")
    false
  end

  def has_setup_menu?
    return true if has_active_role? && has_parent_menu?("setup")
    false
  end

  def menu_masters
    if has_entry_menu?
      menu_by_group("master")
    end
  end

  def menu_locations
    if has_entry_menu?
      menu_by_group("location")
    end
  end

  def menu_accounts
    if has_setup_menu?
      menu_by_group("account")
    end
  end

  def menu_asset_components
    if has_entry_menu?
      menu_by_group("asset_and_component")
    end
  end

  def menu_assets
    if has_entry_menu?
      menu_by_group("asset")
    end
  end

  def menu_roles
    if has_setup_menu?
      menu_by_group("role")
    end
  end

  private
    def menu_by_group(group_name)
      current_account.role.function_accesses
        .joins(:route_paths, :role_function_accesses)
        .where(route_paths: { group: group_name })
        .where(
          "
            role_function_accesses.allow_create = ? OR
            role_function_accesses.allow_read = ? OR
            role_function_accesses.allow_update = ? OR
            role_function_accesses.allow_delete = ? OR
            role_function_accesses.allow_confirm = ?
          ",
          true, true, true, true, true
        ).uniq
    end

    def has_parent_menu?(parent_name)
      current_account.role.function_accesses
        .joins(:route_paths, :role_function_accesses)
        .where(route_paths: { parent: parent_name })
        .where(
          "
            role_function_accesses.allow_create = ? OR
            role_function_accesses.allow_read = ? OR
            role_function_accesses.allow_update = ? OR
            role_function_accesses.allow_delete = ? OR
            role_function_accesses.allow_confirm = ?
          ",
          true, true, true, true, true
        ).present?
    end

    def has_active_role?
      current_account.role.active
    end
end
