class Site < ApplicationRecord
  include Trackable
  include Downcaseable

  belongs_to :site_stat
  belongs_to :site_group

  has_many :user_assets, dependent: :restrict_with_error
  has_many :capital_proposals, dependent: :restrict_with_error

  # downcase_fields :name
  validates :id_site, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_associations(auth_object = nil)
    ["site_group", "site_stat"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "id_site", "id", "ip_address", "name", "request_id", "site_group_id", "site_stat_id", "updated_at", "user_agent"]
  end
end
