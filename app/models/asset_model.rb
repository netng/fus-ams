class AssetModel < ApplicationRecord
  include Trackable
  include Downcaseable

  belongs_to :brand
  belongs_to :asset_type
  belongs_to :asset_item_type

  has_many :assets, dependent: :restrict_with_error

  before_validation :strip_and_upcase_id_asset_model


  # downcase_fields :name

  validates :id_asset_model, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_associations(auth_object = nil)
    [ "asset_item_type", "asset_type", "brand" ]
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "asset_item_type_id", "asset_type_id", "brand_id", "created_at", "created_by", "description", "id_asset_model", "id", "ip_address", "name", "request_id", "updated_at", "user_agent" ]
  end

  private
    def strip_and_upcase_id_asset_model
      if id_asset_model.present?
        self.id_asset_model = id_asset_model.strip.upcase
      end
    end
end
