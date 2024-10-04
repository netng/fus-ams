module Admin
  class VendorsController < ApplicationAdminController
    before_action :set_vendor, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = Vendor.ransack(params[:q])
			scope = @q.result
			@pagy, @vendors = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @vendor = Vendor.new
    end

    def create
      authorize :authorization, :create?

      @vendor = Vendor.new(vendor_params)

      respond_to do |format|
        if @vendor.save
          format.html { redirect_to admin_vendors_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.vendor"))}
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
				if @vendor.update(vendor_params)
					format.html { redirect_to admin_vendors_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.vendor")) }
				else
					format.html { render :new, status: :unprocessable_entity }
				end
			end
    end

    def destroy
      authorize :authorization, :destroy?

    end

    def destroy_many
      authorize :authorization, :destroy?

      vendor_ids = params[:vendor_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				vendors = Vendor.where(id: vendor_ids)

				vendors.each do |vendor|
					unless vendor.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = vendors.map { |vendor| vendor.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_vendors_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_vendors_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.vendor")) }
					end
				end
			end
    end


    private

      def vendor_params
        params.require(:vendor).permit(:name, :address1, :address2, :city, :postal_code, :phone_number, :fax_number, :contact_person, :email, :description)
      end

      def set_vendor
        @vendor = Vendor.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_MST_VENDOR
      end
  end
end