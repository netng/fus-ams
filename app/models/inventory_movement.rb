class InventoryMovement < ApplicationRecord
  belongs_to :source_site, class_name: "Site", foreign_key: "source_site_id"
  belongs_to :destination_site, class_name: "Site", foreign_key: "destination_site_id", optional: true
  belongs_to :user_asset, optional: true

  has_many :inventory_movement_details, dependent: :destroy
  accepts_nested_attributes_for :inventory_movement_details, allow_destroy: true, reject_if: :all_blank

  MOVEMENT_STATUSES = %w[IN_PROGRESS IN_TRANSIT COMPLETED CANCELLED].freeze
  MOVEMENT_TYPES = %w[DIRECT_ISSUE SITE_TRANSFER].freeze

  validates :movement_type, inclusion: { in: MOVEMENT_TYPES }, length: { maximum: 100 }
  validates :status, inclusion: { in: MOVEMENT_STATUSES }, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.set_id_inventory_movement
    date_str = Time.now.strftime("%Y%m%d%H%M")
    random_number = rand(10000..99999).to_s
    "MVMNT-#{date_str}-#{random_number}"
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "destination_site_id", "id", "id_inventory_movement", "ip_address", "movement_type", "quantity", "request_id", "source_site_id", "status", "updated_at", "user_agent", "user_asset_id"]
  end
end
