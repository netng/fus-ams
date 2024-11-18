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
    @has_entry_menu ||= has_active_role? && has_parent_menu?("entry")
  end

  def has_setup_menu?
    @has_setup_menu ||= has_active_role? && has_parent_menu?("setup")
  end

  def menu_masters
    @menu_masters ||= menu_by_group("master") if has_entry_menu?
  end

  def menu_locations
    @menu_locations ||= menu_by_group("location") if has_entry_menu?
  end

  def menu_asset_components
    @menu_asset_components ||= menu_by_group("asset_and_component") if has_entry_menu?
  end

  def menu_assets
    @menu_assets ||= menu_by_group("asset") if has_entry_menu?
  end

  def menu_accounts
    @menu_accounts ||= menu_by_group("account") if has_setup_menu?
  end

  def menu_roles
    @menu_roles ||= menu_by_group("role") if has_setup_menu?
  end

  private
    def menu_by_group(group_name)
      @menu_by_group ||= {}
      @menu_by_group[group_name] = current_account.role.function_accesses
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
      @has_parent_menu ||= {}
      @has_parent_menu[parent_name] ||= current_account.role.function_accesses
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
      @has_active_role ||= current_account.role.active
    end
end
