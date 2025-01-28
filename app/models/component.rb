class Component < ApplicationRecord
  belongs_to :component_type
  has_many :asset_components, inverse_of: :component
  has_many :assets, through: :asset_components, dependent: :restrict_with_error

  include Trackable
  include Downcaseable

  # downcase_fields :name
  before_validation :strip_and_upcase_id_component

  validates :id_component, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_associations(auth_object = nil)
    ["component_type"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["component_type_id", "created_at", "created_by", "description", "id_component", "id", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end

  private
    def strip_and_upcase_id_component
      if id_component.present?
        self.id_component = id_component.strip.upcase
      end
    end
end
