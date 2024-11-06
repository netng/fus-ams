class AssetComponent < ApplicationRecord
  belongs_to :asset, inverse_of: :asset_components, optional: true
  belongs_to :component, inverse_of: :asset_components, optional: true
end
