class AddCreatedByRequestIdUserAgentIpAddressToRequestForPurchaseDetails < ActiveRecord::Migration[8.0]
  def change
    add_column :request_for_purchase_details, :created_by, :string
    add_column :request_for_purchase_details, :request_id, :string
    add_column :request_for_purchase_details, :user_agent, :string
    add_column :request_for_purchase_details, :ip_address, :string
  end
end
