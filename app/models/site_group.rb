class SiteGroup < ApplicationRecord
  include Trackable
  include Downcaseable
  
  belongs_to :project
  
  downcase_fields :name
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
end
