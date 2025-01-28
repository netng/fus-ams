class ChangeSiteToNotNullAtAccounts < ActiveRecord::Migration[8.0]
  def change
    remove_index :accounts, :site_id
    change_column :accounts, :site_id, :uuid, null: false
    add_index :accounts, :site_id
  end
end
