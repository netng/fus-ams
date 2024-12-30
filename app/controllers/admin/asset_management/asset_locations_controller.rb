module Admin::AssetManagement
  class AssetLocationsController < ApplicationAdminController
    def index
      authorize :authorization, :read?

      @q = UserAsset.ransack(params[:q])
      @q.sorts = [ "id_user_asset asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:site, :department)
      @pagy, @asset_locations = pagy(scope, limit: 5)
    end

    def update_asset_location
      authorize :authorization, :update?
    end

    def search_asset
      authorize :authorization, :update?
      asset = Asset.where("tagging_id ILIKE ?", "%#{params[:tagging_id]}%").limit(20)

      puts asset.inspect
    end
  end
end
