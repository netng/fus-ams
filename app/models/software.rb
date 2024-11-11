class Software < ApplicationRecord
  include Trackable
  include Downcaseable

  has_many :asset_softwares, inverse_of: :software
  has_many :assets, through: :asset_softwares, dependent: :restrict_with_error

  # downcase_fields :name
  before_validation :strip_and_upcase_id_software

  validates :id_software, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "id_software", "id", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end

  private
    def strip_and_upcase_id_software
      if id_software.present?
        self.id_software = id_software.strip.upcase
      end
    end
end
