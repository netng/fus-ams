class Asset < ApplicationRecord
  include Trackable

  belongs_to :project
  belongs_to :site
  belongs_to :asset_model
  belongs_to :user_asset
  belongs_to :delivery_order, optional: true
  belongs_to :asset_class, optional: true

  validates :tagging_id, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :computer_name, length: { maximum: 100 }
  validates :computer_ip, length: { maximum: 100 }
  validates :cpu_sn, length: { maximum: 100 }
  validates :monitor_sn, length: { maximum: 100 }
  validates :keyboard_sn, length: { maximum: 100 }
  validates :shipping_date, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  before_validation :strip_and_upcase_tagging_id
  
  def self.ransackable_attributes(auth_object = nil)
    ["asset_class_id", "asset_model_id", "computer_ip", "computer_name", "cpu_sn", "created_at", "created_by", "delivery_order_id", "description", "id", "ip_address", "keyboard_sn", "monitor_sn", "project_id", "request_id", "shipping_date", "site_id", "tagging_date", "tagging_id", "updated_at", "user_agent", "user_asset_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["asset_class", "asset_model", "delivery_order", "project", "site", "user_asset"]
  end

  private
    def strip_and_upcase_tagging_id
      if tagging_id.present?
        self.tagging_id = tagging_id.strip.upcase
      end
    end
  
end
