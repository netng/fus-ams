class Site < ApplicationRecord
  include Trackable
  include Downcaseable

  before_validation :strip_and_upcase_id_site

  belongs_to :site_stat
  belongs_to :site_group

  has_one :site_default

  has_many :user_assets, dependent: :restrict_with_error
  has_many :capital_proposals, dependent: :restrict_with_error
  has_many :assets, dependent: :restrict_with_error
  has_many :accounts, dependent: :restrict_with_error

  # self join
  has_many :child_sites, class_name: "Site", foreign_key: "parent_site_id"
  belongs_to :parent_site, class_name: "Site", optional: true

  # downcase_fields :name
  validates :id_site, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_associations(auth_object = nil)
    [ "site_group", "site_stat", "parent_site" ]
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "created_by", "description", "parent_site_id", "id_site", "id", "ip_address", "name", "request_id", "site_group_id", "site_stat_id", "updated_at", "user_agent" ]
  end

  def strip_and_upcase_id_site
    if id_site.present?
      self.id_site = id_site.strip.upcase
    end
  end
end
