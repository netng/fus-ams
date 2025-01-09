module Admin::InventoryManagement
  class InventoriesController < ApplicationAdminController
    before_action :set_function_access_code
    before_action :set_inventory, only: [ :show, :edit, :update ]
    before_action :set_parent_site, only: [ :new, :create, :edit ]

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
    end

    def create
      authorize :authorization, :create?

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
        asset_exist_in_inventory = Inventory.where(asset_id: asset.id, site_id: site_id)

        if asset_exist_in_inventory.present?
          flash.now[:alert] = "Asset with tagging id: #{tagging_id} already exist in data inventory at site: #{site&.name}"
          render turbo_stream: turbo_stream.replace(
            "flash-message",
            partial: "shared/flash",
            local: { flash: flash }
          ) and return
        else
          Inventory.create(asset_id: asset.id, site_id: site.id, rooms_storage_units_bin_id: rooms_storage_units_bin_id, status: "IN_STOCK")
        end
      end
      redirect_to admin_inventories_path, notice: "Successfully added assets to inventory"
    end

    def edit
      authorize :authorization, :update?

      @inventory_locations = InventoryLocation
        .where(site_id: @inventory.site_id)
        &.pluck(:floor, :id)
      @selected_inventory_location_id = @inventory.rooms_storage_units_bin.rooms_storage_unit.room.inventory_location.id

      @rooms = Room
        .where(inventory_location_id: @selected_inventory_location_id)
        &.pluck(:name, :id)
      @selected_room_id = @inventory.rooms_storage_units_bin.rooms_storage_unit.room.id

      @rooms_storage_units = RoomsStorageUnit
        .joins(:storage_unit)
        .where(room_id: @selected_room_id)
        .select("rooms_storage_units.id, rooms_storage_units.label, storage_units.name")
        &.pluck(:id, :label, :name)
      @selected_rooms_storage_unit_id = @inventory.rooms_storage_units_bin.rooms_storage_unit.id

      @rooms_storage_units_bins = RoomsStorageUnitsBin
        .where(rooms_storage_unit_id: @selected_rooms_storage_unit_id)
        &.pluck(:label, :id)
      @selected_rooms_storage_units_bin_id = @inventory.rooms_storage_units_bin.id

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
          locals: {
            inventory_locations: @inventory_locations,
            option_disabled: query.blank?,
            selected_inventory_location_id: nil,
            selected_room_id: nil
          }
        ),

        turbo_stream.replace(
          "rooms",
          partial: "admin/inventory_management/inventories/rooms",
          locals: {
            rooms: [],
            option_disabled: true,
            selected_room_id: nil
          }
        ),

        turbo_stream.replace(
        "rooms-storage-units",
          partial: "admin/inventory_management/inventories/rooms_storage_units",
          locals: {
            rooms_storage_units: [],
            option_disabled: true,
            selected_rooms_storage_unit_id: nil
          }
        ),

        turbo_stream.replace(
        "rooms-storage-units-bins",
          partial: "admin/inventory_management/inventories/rooms_storage_units_bins",
          locals: {
            rooms_storage_units_bins: [],
            option_disabled: true,
            selected_rooms_storage_units_bin_id: nil
          }
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
          locals: {
            rooms: @rooms,
            option_disabled: query.blank?,
            selected_room_id: nil
          }
        ),

        turbo_stream.replace(
          "rooms-storage-units",
          partial: "admin/inventory_management/inventories/rooms_storage_units",
          locals: {
            rooms_storage_units: [],
            option_disabled: true,
            selected_rooms_storage_unit_id: nil
            }
        ),

        turbo_stream.replace(
          "rooms-storage-units-bins",
          partial: "admin/inventory_management/inventories/rooms_storage_units_bins",
          locals: {
            rooms_storage_units_bins: [],
            option_disabled: true,
            selected_rooms_storage_units_bin_id: nil
          }
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
          locals: {
            rooms_storage_units: @rooms_storage_units,
            option_disabled: query.blank?,
            selected_rooms_storage_unit_id: nil
          }
        ),

        turbo_stream.replace(
          "rooms-storage-units-bins",
          partial: "admin/inventory_management/inventories/rooms_storage_units_bins",
          locals: {
            rooms_storage_units_bins: [],
            option_disabled: true,
            selected_rooms_storage_units_bin_id: nil
          }
        )
      ]
    end

    def rooms_storage_unit_bins
      authorize :authorization, :read?

      query = params[:query]

      @rooms_storage_units_bins = RoomsStorageUnitsBin.where(rooms_storage_unit_id: query)&.pluck(:label, :id)

      render turbo_stream: turbo_stream.replace(
        "rooms-storage-units-bins",
        partial: "admin/inventory_management/inventories/rooms_storage_units_bins",
        locals: {
          rooms_storage_units_bins: @rooms_storage_units_bins,
          option_disabled: query.blank?,
          selected_rooms_storage_units_bin_id: nil
        }
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
        params.expect(inventory: [ :site_id, :status ])
      end

      def set_inventory
        @inventory = Inventory.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_INVMGMT_DATA_INVENTORY
      end


      def set_parent_site
        if current_account.site.site_default.blank?
          @parent_sites = Site.where(id: current_account.site.id).pluck(:name, :id)
        else
          @parent_sites = Site.where(parent_site_id: nil).pluck(:name, :id)
        end
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
