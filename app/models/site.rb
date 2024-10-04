class Site < ApplicationRecord
  include Trackable
  include Downcaseable

  belongs_to :site_stat
  belongs_to :site_group

  downcase_fields :name
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  
end
