class AssetSchedule < ApplicationRecord
  include Trackable

  has_many :assets, dependent: :restrict_with_error

  before_validation :strip_and_upcase_asset_schedule_name

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "id", "name", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "assets" ]
  end

  private
    def strip_and_upcase_asset_schedule_name
      if name.present?
        self.name = name.strip.gsub(/\s+/, ' ').upcase
      end
    end
end
