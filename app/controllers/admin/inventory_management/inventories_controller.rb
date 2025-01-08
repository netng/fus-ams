module Admin::InventoryManagement
  class InventoriesController < ApplicationAdminController
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      if current_account.site.site_default.blank?
        @q = Inventory.joins(:site).where(sites: { id: current_account.site.id })
          .or(Inventory.joins(:site).where(sites: { parent_site: current_account.site }))
          .ransack(params[:q])

        @parent_sites = Site.where(id: current_account.site.id).pluck(:name, :id)
      else
        @q = Inventory.ransack(params[:q])
        @parent_sites = Site.where(parent_site_id: nil).pluck(:name, :id)
      end

      @q.sorts = [ "tagging_id asc" ] if @q.sorts.empty?
      scope = @q.result.includes(
        :site,
        :rooms_storage_units_bin
      )

      if params[:q]
        site_id = params[:q][:site_id_eq]

        if site_id.present?
          site_ids = Site.where(id: site_id)
            .or(Site.where(parent_site_id: site_id))
            .pluck(:id)

          scope = scope.where(site_id: site_ids)
        end
      end

      @pagy, @inventories = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?
      @inventory = Inventory.new

      if current_account.site.site_default.blank?
        @parent_sites = Site.where(id: current_account.site.id).pluck(:name, :id)
      else
        @parent_sites = Site.where(parent_site_id: nil).pluck(:name, :id)
      end
    end

    def create
      authorize :authorization, :create?

      if current_account.site.site_default.blank?
        @parent_sites = Site.where(id: current_account.site.id).pluck(:name, :id)
      else
        @parent_sites = Site.where(parent_site_id: nil).pluck(:name, :id)
      end

      site_id = params[:inventory][:site_id]
      inventory_location_id = params[:q][:rooms_storage_units_bin_rooms_storage_unit_room_inventory_location_id_eq]
      room_id = params[:q][:rooms_storage_units_bin_rooms_storage_unit_room_id_eq]
      rooms_storage_unit_id = params[:q][:rooms_storage_units_bin_rooms_storage_unit_id_eq]
      rooms_storage_units_bin_id = params[:q][:rooms_storage_units_bin_id_eq]
      tagging_ids = params[:tagging_ids]

      validate_presence_of(site_id, "Please select site") and return
      validate_presence_of(inventory_location_id, "Please select inventory location") and return
      validate_presence_of(room_id, "Please select room") and return
      validate_presence_of(rooms_storage_unit_id, "Please select storage unit") and return
      validate_presence_of(rooms_storage_units_bin_id, "Please select storage bin") and return
      validate_presence_of(tagging_ids, "Please select at least one tagging id") and return


      @inventory = Inventory.new(inventory_params)
      site = Site.find(site_id)

      tagging_ids.each do |tagging_id|
        asset = Asset.find_by(tagging_id: tagging_id)
        logger.debug "ASSET : #{asset.inspect}"
        logger.debug "SITE ID: #{site_id}"
        asset_exist_in_inventory = Inventory.where(asset_id: asset.id, site_id: site_id)
        if asset_exist_in_inventory.present?
          flash.now[:alert] = "Asset with tagging id: #{tagging_id} already exist in data inventory at site: #{site&.name}"
          logger.debug "FLASH: #{flash.inspect}"
          render turbo_stream: turbo_stream.replace(
            "flash-message",
            partial: "shared/flash",
            local: { flash: flash }
          ) and return
        else
          Inventory.create(asset_id: asset.id, site_id: site.id, rooms_storage_units_bin_id: rooms_storage_units_bin_id)
        end
      end
      redirect_to admin_inventories_path, notice: "Successfully added assets to inventory"
    end

    def edit
      authorize :authorization, :update?
    end

    def update
      authorize :authorization, :update?
    end

    def destroy_many
      authorize :authorization, :destroy?
    end


    def inventory_locations
      authorize :authorization, :read?

      query = params[:query]

      @inventory_locations = InventoryLocation.where(site_id: query)&.pluck(:floor, :id)

      render turbo_stream: [
        turbo_stream.replace(
          "inventory-locations",
          partial: "admin/inventory_management/inventories/inventory_locations",
          locals: { inventory_locations: @inventory_locations, option_disabled: query.blank? }
        ),

        turbo_stream.replace(
          "rooms",
          partial: "admin/inventory_management/inventories/rooms",
          locals: { rooms: [], option_disabled: true }
        ),

        turbo_stream.replace(
        "rooms-storage-units",
        partial: "admin/inventory_management/inventories/rooms_storage_units",
        locals: { rooms_storage_units: [], option_disabled: true }
        )
      ]
    end

    def rooms
      authorize :authorization, :read?

      query = params[:query]

      @rooms = Room.where(inventory_location_id: query)&.pluck(:name, :id)

      render turbo_stream: [
        turbo_stream.replace(
          "rooms",
          partial: "admin/inventory_management/inventories/rooms",
          locals: { rooms: @rooms, option_disabled: query.blank? }
        ),

        turbo_stream.replace(
        "rooms-storage-units",
        partial: "admin/inventory_management/inventories/rooms_storage_units",
        locals: { rooms_storage_units: [], option_disabled: true }
        ),

        turbo_stream.replace(
        "rooms-storage-unit-bins",
        partial: "admin/inventory_management/inventories/rooms_storage_unit_bins",
        locals: { rooms_storage_unit_bins: [], option_disabled: true }
        )
      ]
    end

    def rooms_storage_units
      authorize :authorization, :read?

      query = params[:query]

      @rooms_storage_units = RoomsStorageUnit
        .joins(:storage_unit)
        .where(room_id: query)
        .select("rooms_storage_units.id, rooms_storage_units.label, storage_units.name")
        &.pluck(:id, :label, :name)

      render turbo_stream: [
        turbo_stream.replace(
          "rooms-storage-units",
          partial: "admin/inventory_management/inventories/rooms_storage_units",
          locals: { rooms_storage_units: @rooms_storage_units, option_disabled: query.blank? }
        ),

        turbo_stream.replace(
          "rooms-storage-unit-bins",
          partial: "admin/inventory_management/inventories/rooms_storage_unit_bins",
          locals: { rooms_storage_unit_bins: [], option_disabled: true }
        )
      ]
    end

    def rooms_storage_unit_bins
      authorize :authorization, :read?

      query = params[:query]

      @rooms_storage_unit_bins = RoomsStorageUnitsBin.where(rooms_storage_unit_id: query)&.pluck(:label, :id)

      render turbo_stream: turbo_stream.replace(
        "rooms-storage-unit-bins",
        partial: "admin/inventory_management/inventories/rooms_storage_unit_bins",
        locals: { rooms_storage_unit_bins: @rooms_storage_unit_bins, option_disabled: query.blank? }
      )
    end

    def find_assets_not_in_inventory
      authorize :authorization, :update?

      site_id = params[:site_id]

      # jika site dari current_account tidak ada di table site_defaults
      if current_account.site.site_default.blank?
        # cari data asset yang belum ada di table inventories
        # jika sudah ada di table inventories, cari yang status = "MOVED" dan site_id != current_account.site.id
        # ambil hanya 100 data
        @assets = Asset
          .joins(:site)
          .left_joins(:inventories)
          .where(
            "inventories.id IS NULL OR (inventories.status = ? AND inventories.site_id != ?)",
            "MOVED", current_account.site.id
          )
          .where(sites: { id: current_account.site.id })
          .or(
            Asset
            .joins(:site)
            .left_joins(:inventories)
            .where(
              "inventories.id IS NULL OR (inventories.status = ? AND inventories.site_id != ?)",
              "MOVED", current_account.site.id
            )
            .where(sites: { parent_site: current_account.site })
          )
          .where("tagging_id ILIKE ?", "%#{params[:tagging_id]}%")
          .select(:id, :tagging_id, :site_id, :user_asset_id)
          .limit(100)
      else
        # jika site dari current_user ada di site_defaults
        @assets = Asset
          .joins(:site)
          .left_joins(:inventories)
          .where(
              "inventories.id IS NULL OR (inventories.status = ? AND inventories.site_id != ?)",
              "MOVED", site_id
          )
          .where(sites: { id: site_id })
          .where("tagging_id ILIKE ?", "%#{params[:tagging_id]}%").limit(20)
          .select(:id, :tagging_id, :site_id, :user_asset_id)
          .limit(100)
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
      def inventory_params
        params.expect(inventory: [ :site_id ])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_INVMGMT_DATA_INVENTORY
      end

      def validate_presence_of(value, message)
        if value.blank?
          flash.now[:alert] = message
          render turbo_stream: turbo_stream.replace(
            "flash-message",
            partial: "shared/flash",
            local: { flash: flash }
          )
        end
      end
  end
end
