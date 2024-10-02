class AddCreatedByRequestIdUserAgentIpAddressToBrands < ActiveRecord::Migration[8.0]
  def change
    add_column :brands, :created_by, :string
    add_column :brands, :request_id, :string
    add_column :brands, :user_agent, :string
    add_column :brands, :ip_address, :string
  end
end
