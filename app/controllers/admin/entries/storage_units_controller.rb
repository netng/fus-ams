module Admin::Entries
  class StorageUnitsController < ApplicationAdminController
    before_action :set_storage_unit, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :edit, :new, :create, :update ]
    before_action :set_previous_url


    def index
      authorize :authorization, :index?

      @q = StorageUnit.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @storage_units = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @storage_unit = StorageUnit.new
    end

    def create
      authorize :authorization, :create?

      @storage_unit = StorageUnit.new(storage_unit_params)

      respond_to do |format|
        if @storage_unit.save
          format.html { redirect_to admin_storage_units_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.storage_unit")) }
        else
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
        if @storage_unit.update(storage_unit_params)
          format.html { redirect_to admin_storage_units_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.storage_unit")) }
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

      storage_unit_ids = params[:storage_unit_ids]

      ActiveRecord::Base.transaction do
        storage_units = StorageUnit.where(id: storage_unit_ids)

        storage_units.each do |storage_unit|
          unless storage_unit.destroy
            redirect_to admin_storage_units_path, alert: "#{storage_unit.errors.full_messages.join("")} - #{t('activerecord.models.storage_unit')} id: #{storage_unit.id_storage_unit}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_storage_units_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.storage_unit")) }
        end
      end
    end

    private
      def storage_unit_params
        params.expect(storage_unit: [ :name, :description ])
      end

      def set_storage_unit
        @storage_unit = StorageUnit.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_MST_STORAGE_UNIT
      end

      def ensure_frame_response
        redirect_to admin_storage_units_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = request.referer || admin_storage_units_path || root_path
      end
  end
end
