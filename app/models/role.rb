class Role < ApplicationRecord
  include Trackable
  include Downcaseable

  downcase_fields :name
  validates :name, presence: true, uniqueness: true
end
