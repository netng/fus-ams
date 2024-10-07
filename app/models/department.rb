class Department < ApplicationRecord
  include Trackable
  include Downcaseable

  downcase_fields :name
  downcase_fields :floor
  
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :floor, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }


  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "floor", "id", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end

end
