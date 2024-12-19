module Admin::Entries
  class InventoryLocationsController < ApplicationAdminController
    before_action :set_inventory_location, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    #before_action :ensure_frame_response, only: [ :show ]
    before_action :set_previous_url


    def index
      authorize :authorization, :index?

      @q = InventoryLocation.ransack(params[:q])
      @q.sorts = [ "floor ascname" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @inventory_locations = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @inventory_location = InventoryLocation.new
      @inventory_location.site = current_account.site
    end

    def add_fields
      authorize :authorization, :create?

      # https://stackoverflow.com/questions/71713303/rails-7-dynamic-nested-forms-with-hotwire-turbo-frames/71715794#71715794
      form_model, *nested_attributes = params[:name].split(/\[|\]/).compact_blank
      helpers.fields form_model.classify.constantize.new do |form|
        nested_form_builder_for form, nested_attributes do |f|
      # NOTE: this block should run only once for the last association
      #       cocktail[cocktail_ingredients_attributes]
      #           this ^^^^^^^^^^^^^^^^^^^^        or this vvvvvv
      #       cocktail[cocktail_ingredients_attributes][0][things_attributes]
      #
      #       `f` is the last nested form builder, for example:
      #
      #         form_with model: Model.new do |f|
      #           f.fields_for :one do |ff|
      #             ff.fields_for :two do |fff|
      #               yield fff
      #               #     ^^^
      #               # NOTE: this is what you should get in this block
      #             end
      #           end
      #         end
      #
      render turbo_stream: turbo_stream.append(
        params[:name].parameterize(separator: "_"),
        partial: "#{f.object.class.name.underscore}_fields",
        locals: { f: }
      )
        end
      end
    end

    def create
      authorize :authorization, :create?

      @inventory_location = InventoryLocation.new(inventory_location_params)
      @inventory_location.site = current_account.site

      respond_to do |format|
        begin
          if @inventory_location.save
            format.html { redirect_to admin_inventory_locations_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.inventory_location")) }
          else
            format.html { render :new, status: :unprocessable_entity }
          end
        rescue ActiveRecord::RecordNotUnique => e
          handle_unique_constraint_error(e)
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize :authorization, :update?
    end

    def update
      authorize :authorization, :update?

      respond_to do |format|
        if @inventory_location.update(inventory_location_params)
          format.html { redirect_to admin_inventory_locations_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.inventory_location")) }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize :authorization, :destroy?
    end

    def destroy_many
      authorize :authorization, :destroy?

      inventory_location_ids = params[:inventory_location_ids]

      ActiveRecord::Base.transaction do
        inventory_locations = InventoryLocation.where(id: inventory_location_ids)

        inventory_locations.each do |inventory_location|
          unless inventory_location.destroy
            redirect_to admin_inventory_locations_path, alert: "#{inventory_location.errors.full_messages.join("")} - #{t('activerecord.models.inventory_location')} id: #{inventory_location.id_inventory_location}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_inventory_locations_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.inventory_location")) }
        end
      end
    end

    private
      def inventory_location_params
        params.expect(inventory_location: [
          :floor,
          :description,
          rooms_attributes: [ [
            :id,
            :name,
            :description,
            :_destroy,
            rooms_storage_units_attributes: [ [
              :id,
              :storage_unit_id,
              :label,
              :capacity,
              :description,
              :_destroy,
              rooms_storage_units_bins_attributes: [ [
                :id,
                :rooms_storage_unit_id,
                :label,
                :description,
                :_destroy
              ] ]
            ] ]
          ] ]
        ])
      end

      def set_inventory_location
        @inventory_location = InventoryLocation.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ASS_INVENTORY_LOCATION
      end

      def ensure_frame_response
        redirect_to admin_inventory_locations_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = request.referer || admin_inventory_locations_path || root_path
      end

      def handle_unique_constraint_error(exception)
        if exception.message.include?("index_rooms_on_name_and_inventory_location_id") ||
            exception.message.include?("idx_on_label_room_id_storage_unit_id_10022de3c0") ||
            exception.message.include?("idx_on_label_rooms_storage_unit_id_fdfa0f7385")


          @inventory_location.rooms.each do |room|
            # Periksa konflik di database
            db_conflict = Room.exists?(name: room.name, inventory_location_id: room.inventory_location_id)

            # Periksa konflik di memori (nested attributes)
            memory_conflict = @inventory_location.rooms.any? do |other_room|
              other_room != room && other_room.name == room.name
            end

            if db_conflict || memory_conflict
              room.errors.add(
                :name,
                I18n.t(
                  "custom.errors.nested_uniqueness_scope",
                  field: Room.human_attribute_name(:name),
                  related_model: InventoryLocation.model_name.human
                )
              )
            end

            # Validasi rooms_storage_units
            room.rooms_storage_units.each do |storage_unit|
              logger.debug "Storage UNIT: #{storage_unit.inspect}"
              # Periksa konflik di database
              db_conflict_storage = RoomsStorageUnit.exists?(label: storage_unit.label, room_id: storage_unit.room_id, storage_unit_id: storage_unit.storage_unit_id)

              # Periksa konflik di memori (nested attributes)
              memory_conflict_storage = room.rooms_storage_units.any? do |other_storage_unit|
                other_storage_unit != storage_unit && other_storage_unit.label == storage_unit.label && other_storage_unit.storage_unit_id == storage_unit.storage_unit_id
              end

              if db_conflict_storage || memory_conflict_storage
                storage_unit.errors.add(
                  :label,
                  I18n.t(
                    "custom.errors.nested_uniqueness_scope",
                    field: RoomsStorageUnit.human_attribute_name(:label),
                    related_model: Room.model_name.human
                  )
                )

                logger.debug "Storage unit error: #{storage_unit.errors.inspect}"
              end

              # Validasi rooms_storage_units_bins
              storage_unit.rooms_storage_units_bins.each do |storage_bin|
                logger.debug "Storage UNIT bins: #{storage_bin.inspect}"
                # Periksa konflik di database
                db_conflict_storage = RoomsStorageUnitsBin.exists?(label: storage_bin.label, rooms_storage_unit_id: storage_bin.rooms_storage_unit_id)

                # Periksa konflik di memori (nested attributes)
                memory_conflict_storage = storage_unit.rooms_storage_units_bins.any? do |other_storage_bin|
                  other_storage_bin != storage_bin && other_storage_bin.label == storage_bin.label && other_storage_bin.rooms_storage_unit_id == storage_bin.rooms_storage_unit_id
                end

                if db_conflict_storage || memory_conflict_storage
                  storage_bin.errors.add(
                    :label,
                    I18n.t(
                      "custom.errors.nested_uniqueness_scope",
                      field: RoomsStorageUnitsBin.human_attribute_name(:label),
                      related_model: RoomsStorageUnit.model_name.human
                    )
                  )

                  logger.debug "Storage unit error: #{storage_bin.errors.inspect}"
                end
              end
            end
          end
        else
          @inventory_location.errors.add(:base, exception.message)
        end
      end

      def nested_form_builder_for(f, *nested_attributes, &block)
        # https://stackoverflow.com/questions/71713303/rails-7-dynamic-nested-forms-with-hotwire-turbo-frames/71715794#71715794
        attribute, index = nested_attributes.flatten!.shift(2)
        if attribute.blank?
          # NOTE: yield the last form builder instance to render the response
          yield f
          return
        end
        association = attribute.chomp("_attributes")
        child_index = index || Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)
        f.fields_for association, association.classify.constantize.new, child_index: do |ff|
          nested_form_builder_for(ff, nested_attributes, &block)
        end
      end
  end
end
