class Brand < ApplicationRecord
  include Trackable

  validates :name, presence: true, uniqueness: true
end
