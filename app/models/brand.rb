class Brand < ApplicationRecord
  include Trackable

  validates :name, presence: true, uniqueness: true


  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "name"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

end
