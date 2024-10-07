class Component < ApplicationRecord
  belongs_to :component_type

  include Trackable
  include Downcaseable

  downcase_fields :name

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_associations(auth_object = nil)
    ["component_type"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["component_type_id", "created_at", "created_by", "description", "id", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end
end
