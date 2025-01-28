module Admin::AssetManagement
  class AssetLocationsController < ApplicationAdminController
    before_action :set_function_access_code
    def index
      authorize :authorization, :read?
      @q = nil

      if current_account.site.site_default.blank?
        @q = UserAsset.joins(:site).where(sites: { id: current_account.site.id })
          .or(UserAsset.joins(:site).where(sites: { parent_site: current_account.site }))
          .ransack(params[:q])

        @sites = Site.order(:name).where(id: current_account.site.id)
          .or(Site.where(parent_site_id: current_account.site.id))
          .pluck(:id, :name)

      else
        @q = UserAsset.ransack(params[:q])
        @sites = Site.order(:name).pluck(:id, :name)
      end

      @q.sorts = [ "id_user_asset asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:site, :department)
      @pagy, @user_assets = pagy(scope, limit: 3)
    end

    def update_asset_location
      authorize :authorization, :update?
      user_asset = nil
      maybe_error = false

      tagging_ids = params[:tagging_ids]&.flatten&.reject(&:blank?)
      user_asset_id = params[:user_asset_id]

      if tagging_ids.blank? || user_asset_id.blank?
        return redirect_to admin_asset_locations_path, notice: "Please select at least one tagging id & site"
      end

      ActiveRecord::Base.transaction do
        user_asset = UserAsset.find_by(id: user_asset_id)
        if user_asset.blank?
          maybe_error = true
          raise ActiveRecord::RecordNotFound, "User asset is not found"
        end

        tagging_ids.each do |tagging_id|
          asset = Asset.find_by(tagging_id: tagging_id)
          if asset.blank?
            maybe_error = true
            raise ActiveRecord::RecordNotFound, "Asset with tagging_id #{tagging_id} is not found"
          end

          asset.update!(user_asset_id: user_asset.id, site_id: user_asset.site.id)
        end
      end

      unless maybe_error
        redirect_to admin_asset_locations_path, notice: t("custom.flash.notices.successfully.updated_asset_locations", tagging_ids: tagging_ids, site: user_asset.site&.name)
      end

    rescue ActiveRecord::RecordNotFound => e
      redirect_to admin_asset_locations_path, alert: e
    rescue => e
      redirect_to admin_asset_locations_path, alert: "Something goes wrong. Please contact our webmaster"
    end

    def search_asset
      authorize :authorization, :update?

      if current_account.site.site_default.blank?
        @assets = Asset.joins(:site)
          .where(sites: { id: current_account.site.id })
          .or(Asset.joins(:site).where(sites: { parent_site: current_account.site }))
          .where("tagging_id ILIKE ?", "%#{params[:tagging_id]}%")
          .select(:id, :tagging_id, :site_id, :user_asset_id)
          .limit(20)
      else
        @assets = Asset.select(:id, :tagging_id, :site_id, :user_asset_id)
          .where("tagging_id ILIKE ?", "%#{params[:tagging_id]}%").limit(20)
      end

      items = @assets.map do |asset|
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

      puts @assets.inspect
    end

    private
    def set_function_access_code
      @function_access_code = FunctionAccessConstant::FA_ASSMGMT_ASSET_LOCATION
    end
  end
end
