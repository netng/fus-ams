class Brand < ApplicationRecord
  include Trackable
  include Downcaseable

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  downcase_fields :name


  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "name"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

end
