class Brand < ApplicationRecord
  include Trackable
  include Downcaseable

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  downcase_fields :name


  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "name"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

end
