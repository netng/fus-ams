class Department < ApplicationRecord
  include Trackable
  include Downcaseable

  validates :name, presence: true, length: { maximum: 100 }
  validates :floor, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  downcase_fields :name
  downcase_fields :floor

end
