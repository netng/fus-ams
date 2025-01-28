class RoutePath < ApplicationRecord
  include Trackable

  belongs_to :function_access

  validates :path, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :label, presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 500 }
end
