class Project < ApplicationRecord
  include Trackable
  include Downcaseable

  downcase_fields :name
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
end
