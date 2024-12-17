class AssetSchedule < ApplicationRecord
  include Trackable

  has_many :assets, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "id", "name", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "assets" ]
  end
end
