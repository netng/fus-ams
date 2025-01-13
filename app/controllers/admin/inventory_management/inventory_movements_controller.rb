module Admin::InventoryManagement
  class InventoryMovementsController < ApplicationAdminController
    before_action :set_parent_site, only: [ :new ]
    def index
      authorize :authorization, :index?
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @inventory_movement = InventoryMovement.new
    end

    def create
      authorize :authorization, :create?

      @inventory_movement = InventoryMovement.new(inventory_movement_params)
      @inventory_movement.id_inventory_movement = InventoryMovement.set_id_inventory_movement

      movement_type = inventory_movement_params[:type]
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
                  item.update(status: Inventory::STATUSES.first)
                end

              end

              format.html {
                redirect_to admin_inventory_movements_path,
                notice: t("custom.flash.notices.successfully", model: t("activerecord.models.inventory_movement"))
              }
            else
              render :new, status: :unprocessable_entity
            end

          end
        end
      end

    end

    def find_user_assets_by_site
      authorize :authorization, :read?
      query = params[:user_asset]

      user_assets = UserAsset
        .where(
          "id_user_asset ILIKE ? OR aztec_code ILIKE ? OR username ILIKE ? OR email ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
        .where(site_id: params[:site_id])
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

    private
      def inventory_movement_params
        params.expect(inventory_movement: [
          :type,
          :source_site_id,
          :destrination_site_id,
          :user_asset_id,
          :quantity,
          :status,
          :description,
          inventory_movement_details_attributes: [ [
            :id,
            :inventory_movement_id,
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
