module Admin::AssetManagement
  class AssetLocationsController < ApplicationAdminController
    def index
      authorize :authorization, :read?

      @q = UserAsset.ransack(params[:q])
      @q.sorts = [ "id_user_asset asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:site, :department)
      @pagy, @user_assets = pagy(scope, limit: 5)
    end

    def update_asset_location
      authorize :authorization, :update?
      user_asset = nil

      tagging_ids = params[:tagging_ids]&.flatten&.reject(&:blank?)
      user_asset_id = params[:user_asset_id]

      if tagging_ids.blank? || user_asset_id.blank?
        redirect_to admin_asset_locations_path, notice: "Please select at least one tagging id & site"
      end

      ActiveRecord::Base.transaction do
        user_asset = UserAsset.find_by(id: user_asset_id)
        raise ActiveRecord::RecordNotFound, "User asset #{user_asset.id_user_asset} is not found" unless user_asset

        tagging_ids.each do |tagging_id|
          asset = Asset.find_by(tagging_id: tagging_id)
          raise ActiveRecord::RecordNotFound, "Asset with tagging_id #{tagging_id} is not found" unless asset

          asset.update!(user_asset_id: user_asset.id, site_id: user_asset.site.id)
        end
      end

      redirect_to admin_asset_locations_path, notice: t("custom.flash.notices.successfully.updated_asset_locations", tagging_ids: tagging_ids, site: user_asset.site&.name )

    rescue ActiveRecord::RecordNotFound => e
      redirect_to admin_asset_locations_path, alert: e
    rescue => e
        redirect_to admin_asset_locations_path, alert: "Something goes wrong. Please contact our webmaster"
    end

    def search_asset
      authorize :authorization, :update?
      assets = Asset.select(:id, :tagging_id, :site_id, :user_asset_id)
        .where("tagging_id ILIKE ?", "%#{params[:tagging_id]}%").limit(20)

      items = assets.map do |asset|
        {
          id: asset.id,
          tagging_id: asset.tagging_id,
          site: asset.site&.name,
          user_asset_id: asset.user_asset&.id_user_asset,
          user_asset_username: asset.user_asset&.username
        }
      end

      render json: { items: items }

      # render turbo_stream: turbo_stream.replace(
      #   "tagging-ids-select-options",
      #   partial: "admin/asset_management/asset_locations/options",
      #   locals: { assets: assets }
      # )

      puts assets.inspect
    end
  end
end
