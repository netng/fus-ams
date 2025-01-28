class AssetType < ApplicationRecord
  include Trackable
  include Downcaseable

  has_many :asset_item_types, dependent: :restrict_with_error
  has_many :asset_models, dependent: :restrict_with_error

  before_validation :strip_and_upcase_id_asset_type

  # downcase_fields :name

  validates :id_asset_type, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "created_by", "description", "id_asset_type", "id", "ip_address", "name", "request_id", "updated_at", "user_agent" ]
  end

  private
    def strip_and_upcase_id_asset_type
      if id_asset_type.present?
        self.id_asset_type = id_asset_type.strip.upcase
      end
    end
end
