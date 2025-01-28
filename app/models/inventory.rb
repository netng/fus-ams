class Inventory < ApplicationRecord
  belongs_to :site
  belongs_to :asset
  belongs_to :rooms_storage_units_bin

  STATUSES = %w[MOVED IN_STOCK].freeze
  validates :status, inclusion: { in: STATUSES }

  def self.ransackable_attributes(auth_object = nil)
    ["asset_id", "created_at", "id", "inventory_location_id", "rooms_storage_units_bin_id", "site_id", "status", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["asset", "rooms_storage_units_bin", "site"]
  end

  private
    def moved?
      status == "MOVED"
    end

    def in_stock?
      status == "IN_STOCK"
    end
end
