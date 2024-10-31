class AssetClass < ApplicationRecord
  belongs_to :project

  has_many :assets, dependent: :restrict_with_error
end
