class Role < ApplicationRecord
  include Trackable
  include Downcaseable

  has_many :accounts, dependent: :restrict_with_error

  has_many :role_function_accesses, inverse_of: :role
  has_many :function_accesses, through: :role_function_accesses, dependent: :destroy

  accepts_nested_attributes_for :role_function_accesses, allow_destroy: true, reject_if: :all_blank

  downcase_fields :name
  before_validation :remove_trailing_whitespace

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }

  def self.ransackable_attributes(auth_object = nil)
    ["active", "created_at", "created_by", "description", "id", "id_value", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["accounts", "function_accesses", "role_function_accesses"]
  end

  private
    def remove_trailing_whitespace
      self.name = name.strip unless name.blank?
    end
end
