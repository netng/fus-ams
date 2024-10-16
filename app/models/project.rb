class Project < ApplicationRecord
  include Trackable
  include Downcaseable

  has_many :site_groups, dependent: :restrict_with_error
  
  # downcase_fields :name

  validates :id_project, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "id_project", "id", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end

end
