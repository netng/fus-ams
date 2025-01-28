class SiteStat < ApplicationRecord
  include Trackable
  include Downcaseable

  has_many :sites, dependent: :restrict_with_error

  # downcase_fields :name

  validates :id_site_stat, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }

  validates :description, length: { maximum: 500 }
  

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "id", "ip_address", "id_site_stat", "name", "request_id", "updated_at", "user_agent"]
  end

end
