module Admin::Entry
  class VendorsController < ApplicationAdminController
    before_action :set_vendor, only: [ :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :new, :create, :edit, :update ]

    def index
      authorize :authorization, :index?

      @q = Vendor.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @vendors = pagy(scope)
    end

    def new
      authorize :authorization, :create?
      @previous_url = admin_vendors_path || root_path

      @vendor = Vendor.new
    end

    def create
      authorize :authorization, :create?
      @previous_url = admin_vendors_path || root_path


      @vendor = Vendor.new(vendor_params)

      respond_to do |format|
        if @vendor.save
          format.html { redirect_to admin_vendors_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.vendor")) }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize :authorization, :update?
      @previous_url = admin_vendors_path || root_path
    end

    def update
      authorize :authorization, :update?
      @previous_url = admin_vendors_path || root_path


      respond_to do |format|
        if @vendor.update(vendor_params)
          format.html { redirect_to admin_vendors_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.vendor")) }
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

      vendor_ids = params[:vendor_ids]

      ActiveRecord::Base.transaction do
        vendors = Vendor.where(id: vendor_ids)

        vendors.each do |vendor|
          unless vendor.destroy
            redirect_to admin_vendors_path, alert: "#{vendor.errors.full_messages.join("")} - #{t('activerecord.models.vendor')} id: #{vendor.id_vendor}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_vendors_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.vendor")) }
        end
      end
    end

    def import
      authorize :authorization, :create?
    end

    def process_import
      authorize :authorization, :create?
      allowed_extension = [ ".xlsx", ".csv" ]
      file = params[:file]

      if file.present?

        if !allowed_extension.include?(File.extname(file.original_filename))
          return redirect_back_or_to import_admin_brands_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        # buka file menggunakan roo
        xlsx = Roo::Spreadsheet.open(file.path)

        # ambil sheet pertama
        sheet = xlsx.sheet(0)

        vendor_attributes_headers = {
          id_vendor: "Vendor id",
          name: "Name",
          address1: "Address1",
          address2: "Address2",
          city: "City",
          postal_code: "Postal code",
          phone_number: "Phone number",
          fax_number: "Fax number",
          contact_person: "Contact person",
          email: "Email",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(vendor_attributes_headers).each do |row|
              vendor = Vendor.new(
                id_vendor: row[:id_vendor],
                name: row[:name],
                address1: row[:address1],
                address2: row[:address2],
                city: row[:city],
                postal_code: row[:postal_code],
                phone_number: row[:phone_number],
                fax_number: row[:fax_number],
                contact_person: row[:contact_person],
                email: row[:email],
                description: row[:description]
              )

              unless vendor.save
                error_message = vendor.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_vendors_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_vendors_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_vendors_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.vendor")) }
          end
        end
      else
        redirect_back_or_to import_admin_vendors_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def vendor_params
        params.require(:vendor).permit(:id_vendor, :name, :address1, :address2, :city, :postal_code, :phone_number, :fax_number, :contact_person, :email, :description)
      end

      def set_vendor
        @vendor = Vendor.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_MST_VENDOR
      end

      def ensure_frame_response
        redirect_to admin_vendors_path unless turbo_frame_request?
      end
  end
end
