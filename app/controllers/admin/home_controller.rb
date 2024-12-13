module Admin
  class HomeController < ApplicationAdminController
    def index
      skip_authorization

      if current_account.site.site_default.blank?
        @assets_count = Asset.joins(:site).where(sites: { id: current_account.site.id })
          .or(Asset.joins(:site).where(sites: { parent_site: current_account.site }))
          .count

        @user_assets_count = UserAsset.joins(:site).where(sites: { id: current_account.site.id })
          .or(UserAsset.joins(:site).where(sites: { parent_site: current_account.site }))
          .count

        @sites_count = Site.where(id: current_account.site.id)
          .or(Site.where(parent_site: current_account.site.id))
      else
        @assets_count = Asset.count
        @user_assets_count = UserAsset.count
        @sites_count = Site.where(parent_site: nil).count
      end
    end
  end
end
