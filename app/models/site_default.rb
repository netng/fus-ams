class SiteDefault < ApplicationRecord
  include Trackable

  belongs_to :site
  has_many :inventory_locations, dependent: :restrict_with_error

  
  # validates :id_user_site_default, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :id_user_site_default, presence: true, length: { maximum: 100 }
  validates :site, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  
  before_validation :remove_trailing_whitespace
  before_save :upcase_id_user_site_default
  before_destroy :check_user_asset_presence

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "id", "id_user_site_default", "ip_address", "name", "request_id", "site_id", "updated_at", "user_agent"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["site"]
  end

  private
    def remove_trailing_whitespace
      self.id_user_site_default = id_user_site_default.strip
    end

    def upcase_id_user_site_default
      self.id_user_site_default = id_user_site_default.upcase
    end

    def check_user_asset_presence
      if site.user_assets.find_by_id_user_asset(self.id_user_site_default).present?
        errors.add(:base, "Failed to delete Site Default because dependent exist on User Asset")
        throw(:abort)
      end
    end


end
