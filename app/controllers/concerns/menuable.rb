module Menuable
  extend ActiveSupport::Concern

  included do
    helper_method :has_entry_menu?
    helper_method :has_setup_menu?

    helper_method :menu_masters
    helper_method :menu_accounts
    helper_method :menu_roles
  end

  def has_entry_menu?
    return true if current_account.role.function_accesses
      .joins(:route_paths)
      .where(route_paths:
        {
          parent: "entry"
        }
      ).present?

    false
  end

  def menu_masters
    if has_entry_menu?
      menu_masters ||= current_account.role.function_accesses
        .joins(:route_paths)
        .where(route_paths:
          {
            group: "master"
          }
        )
    end
  end

  def has_setup_menu?
    return true if current_account.role.function_accesses
      .joins(:route_paths)
      .where(route_paths:
        {
          parent: "setup"
        }
      ).present?

    false
  end

  def menu_accounts
    if has_setup_menu?
      menu_accounts ||= current_account.role.function_accesses
      .joins(:route_paths)
      .where(route_paths:
        {
          group: "account"
        }
      )
    end
  end

  def menu_roles
    if has_setup_menu?
      menu_roles ||= current_account.role.function_accesses
      .joins(:route_paths)
      .where(route_paths:
        {
          group: "role"
        }
      )
    end
  end


end