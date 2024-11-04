class Project < ApplicationRecord
  include Trackable
  include Downcaseable

  before_validation :strip_and_upcase_id_project

  has_many :site_groups, dependent: :restrict_with_error
  has_many :assets, dependent: :restrict_with_error
  has_many :asset_classes, dependent: :restrict_with_error
  
  # downcase_fields :name

  validates :id_project, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "id_project", "id", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end

  private
    def strip_and_upcase_id_project
      if id_project.present?
        self.id_project = id_project.strip.upcase
      end
    end

end
