module Admin::InventoryManagement
  class InventoryMovementsController < ApplicationAdminController
    before_action :set_parent_site, only: [ :new, :create ]
    def index
      authorize :authorization, :index?

      if current_account.site.site_default.blank?
        @q = InventoryMovement
          .joins(:source_site)
          .where(sites: { id: current_account.site.id })
          .or(
            InventoryMovement
              .joins(:source_site)
          .where(sites: { parent_site: current_account.site })
          )
      else
        @q = InventoryMovement.ransack(params[:q])
      end

      @q.sorts = [ "id_inventory_movement" ] if @q.sorts.empty?
      scope = @q.result.includes(
        :source_site,
        :user_asset,
        :destination_site
      )

      if params[:q]
        site_id = params[:q][:source_site_id_eq]

        if site_id.present?
          site_ids = Site.where(id: site_id)
            .or(Site.where(parent_site_id: site_id))
            .pluck(:id)

          scope = scope.where(site_id: site_ids)
        end
      end

      @pagy, @inventory_movements = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @inventory_movement = InventoryMovement.new
      @inventory_movement.inventory_movement_details.build
    end

    def create
      authorize :authorization, :create?

      # Transform inventory_movement_details_attributes
      if params[:inventory_movement][:inventory_movement_details_attributes].present?
        details = params[:inventory_movement][:inventory_movement_details_attributes].values
        transformed_details = details.flat_map do |detail|
          detail[:inventory_id].reject(&:blank?).map { |id| { inventory_id: id } }
        end

        params[:inventory_movement][:inventory_movement_details_attributes] = transformed_details
      end

      @inventory_movement = InventoryMovement.new(inventory_movement_params)
      @inventory_movement.id_inventory_movement = InventoryMovement.set_id_inventory_movement
      @inventory_movement.quantity = transformed_details.size

      movement_type = inventory_movement_params[:movement_type]
      user_asset = UserAsset.find_by(id: inventory_movement_params[:user_asset_id])
      site_id = inventory_movement_params[:site_id]

      respond_to do |format|
        begin
          ActiveRecord::Base.transaction do
            if @inventory_movement.save
              @inventory_movement.inventory_movement_details.each do |item|

                # Direct transfer asset to user
                if movement_type == InventoryMovement::MOVEMENT_TYPES.first
                  item.inventory.update(status: Inventory::STATUSES.first, site_id: user_asset.site_id)
                  item.inventory.asset.update(user_asset_id: user_asset.id, site_id: user_asset.site_id)
                end

                # Transfer asset to site
                if movement_type == InventoryMovement::MOVEMENT_TYPES.second
                  item.inventory.update(status: Inventory::STATUSES.first)
                end

              end

              format.html {
                redirect_to admin_inventory_movements_path,
                notice: t("custom.flash.notices.successfully", model: t("activerecord.models.inventory_movement"))
              }
            else
              format.html { render :new, status: :unprocessable_entity }
            end

          end
        end
      end

    end

    def find_user_assets_by_site
      authorize :authorization, :read?
      query = params[:user_asset]

      user_assets = UserAsset
        .joins(:site)
        .where(
          "id_user_asset ILIKE ? OR aztec_code ILIKE ? OR username ILIKE ? OR email ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
        .where(site_id: params[:site_id])
        .or(UserAsset.where(sites: { parent_site_id: params[:site_id] } ))
        .select(:id, :id_user_asset, :aztec_code, :username, :email)
        .limit(100)
      
      items = user_assets.map do |user_asset|
        {
          user_asset_id: user_asset.id,
          id_user_asset: user_asset.id_user_asset,
          aztec_code: user_asset.aztec_code,
          username: user_asset.username,
          email: user_asset.email
        }
      end

      render json: { items: items }
    end

    def find_assets_by_site_inventory
      authorize :authorization, :read?
      query = params[:tagging_id]
      site_id = params[:site_id]

      inventories = Inventory
        .joins(:site, :asset)
        .where(
          "sites.id = ? AND assets.tagging_id ILIKE ? AND status = ?",
          site_id, "%#{query}%", Inventory::STATUSES.second
        )
          .select(:id, "sites.name as site_name", :tagging_id, "assets.id as asset_id")

      items = inventories.map do |item|
        {
          id: item.id,
          site_name: item.site_name,
          tagging_id: item.tagging_id,
          asset_id: item.asset_id
        }
      end

      render json: { items: items }
    end

    private
      def inventory_movement_params
        params.expect(inventory_movement: [
          :movement_type,
          :source_site_id,
          :destination_site_id,
          :user_asset_id,
          :quantity,
          :status,
          :description,
          inventory_movement_details_attributes: [ [
            :id,
            :inventory_id,
            :_destroy
          ] ]
        ])
      end

      def set_parent_site
        if current_account.site.site_default.blank?
          @parent_sites = Site.where(id: current_account.site.id).pluck(:name, :id)
        else
          @parent_sites = Site.where(parent_site_id: nil).pluck(:name, :id)
        end
      end
  end
end 
