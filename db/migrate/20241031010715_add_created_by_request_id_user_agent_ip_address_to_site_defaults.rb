class AddCreatedByRequestIdUserAgentIpAddressToSiteDefaults < ActiveRecord::Migration[8.0]
  def change
    add_column :site_defaults, :created_by, :string
    add_column :site_defaults, :request_id, :string
    add_column :site_defaults, :user_agent, :string
    add_column :site_defaults, :ip_address, :string
  end
end
