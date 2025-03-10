class Brand < ApplicationRecord
  include Trackable
  include Downcaseable

  has_many :asset_models, dependent: :restrict_with_error
  before_validation :strip_and_upcase_id_brand

  # validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :id_brand, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "name", "id_brand"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private
    def strip_and_upcase_id_brand
      if id_brand.present?
        self.id_brand = id_brand.strip.upcase
      end
    end
end
