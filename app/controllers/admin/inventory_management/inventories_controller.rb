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
    end

    def create
      authorize :authorization, :create?
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

      @rooms_storage_units = RoomsStorageUnit.where(room_id: query)&.pluck(:label, :id)

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

    private
      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_INVMGMT_DATA_INVENTORY
      end
  end
end
