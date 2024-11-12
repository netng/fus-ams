module Admin
  class DeliveryOrdersController < ApplicationAdminController
    before_action :set_delivery_order, only: [ :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [:new, :create, :edit, :update]

    def index
      authorize :authorization, :index?

      @q = DeliveryOrder.ransack(params[:q])
      @q.sorts = [ "date desc" ] if @q.sorts.empty?
      scope = @q.result.includes(:purchase_order)
      @pagy, @delivery_orders = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @delivery_order = DeliveryOrder.new
      @previous_url = admin_delivery_orders_path || root_path
    end

    def create
      authorize :authorization, :create?

      @delivery_order = DeliveryOrder.new(delivery_order_params)
      @previous_url = admin_delivery_orders_path || root_path

      respond_to do |format|
        if @delivery_order.save
          format.html { redirect_to admin_delivery_orders_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.delivery_order")) }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize :authorization, :update?
      @previous_url = admin_delivery_orders_path || root_path
    end

    def update
      authorize :authorization, :update?
      @previous_url = admin_delivery_orders_path || root_path

      respond_to do |format|
        if @delivery_order.update(delivery_order_params)
          format.html { redirect_to admin_delivery_orders_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.delivery_order")) }
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

      delivery_order_ids = params[:delivery_order_ids]

      ActiveRecord::Base.transaction do
        delivery_orders = DeliveryOrder.where(id: delivery_order_ids)

        delivery_orders.each do |delivery_order|
          unless delivery_order.destroy
            error_message = delivery_order.errors.full_messages.join("")
            redirect_to admin_delivery_orders_path, alert: "#{error_message} - #{t('activerecord.models.delivery_order')} id: #{delivery_order.id_delivery_order}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_delivery_orders_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.delivery_order")) }
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
      data = []
      batch_size = 1000
      maybe_error = false

      start_time = Time.now

      created_by = Current.account.username
      request_id = Current.request_id
      user_agent = Current.user_agent
      ip_address = Current.ip_address

      if file.present?
        if !allowed_extension.include?(File.extname(file.original_filename))
          return redirect_back_or_to import_admin_delivery_orders_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        delivery_order_attributes_headers = {
          number: "Number",
          purchase_order: "PO number",
          date: "Date",
          warranty_expired: "Warranty expired date",
          description: "Description"

        }

        begin
          ActiveRecord::Base.transaction do
            sheet.parse(delivery_order_attributes_headers).each do |row|
              po = PurchaseOrder.find_by_number(row[:purchase_order]&.strip)

              if row[:purchase_order].present?
                if po.nil?
                  # maybe_error = true
                  logger.debug "request_id: #{request.request_id} - DO number: #{row[:number]} - reason: PO number `#{row[:purchase_order]}` is not found"
                  # redirect_back_or_to import_admin_delivery_orders_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.purchase_order"), id: row[:purchase_order])
                  # raise ActiveRecord::Rollback
                  # return

                  # safety net jika po tidak ada namun pada file import dari fus-online po number tertulis ynag sebenernya po tidak ada di db fusonline, mungkin terhapus
                  po = PurchaseOrder.create(
                    number: row[:purchase_order]&.strip,
                    date: Date.today,
                    vendor: Vendor.find_by_id_vendor("safety-net"),
                    request_for_purchase: RequestForPurchase.find_by_number("safety-net-rfp"),
                    delivery_date: Date.today,
                    ship_to_site: PoDeliverySite.find_by_id_po_delivery_site("MD"),
                    payment_remarks: "safety net",
                    approved_by: PersonalBoard.find_by_id_personal_board("sf"),
                    status: "Open"
                  )
                end
              end

              data << {
                number: row[:number]&.strip,
                date: row[:date],
                purchase_order_id: po&.id,
                warranty_expired: row[:warranty_expired],
                description: row[:description]
              }

              if data.size >= batch_size
                DeliveryOrder.insert_all!(data)
                data.clear
              end
            end

            DeliveryOrder.insert_all!(data) unless data.empty?
          end

        rescue Roo::HeaderRowNotFoundError => e
          return redirect_to import_admin_delivery_orders_path, alert: t("custom.errors.invalid_import_template", errors: e)


        # Penanganan untuk duplikat data
        rescue ActiveRecord::RecordNotUnique => e
          logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
          duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
          duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
          humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
          return redirect_back_or_to import_admin_delivery_orders_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

        # penangan error null violation
        rescue ActiveRecord::NotNullViolation => e
          logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
          error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
          error_row = data.find { |r| r[error_column.to_sym].nil? }

          error_message = "#{t('activerecord.attributes.delivery_order.' + error_column)} " \
            "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
          return redirect_back_or_to import_admin_delivery_orders_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

        # Penanganan umum untuk semua jenis error lainnya
        rescue => e
          logger.error "#{Current.request_id} - General error during import: #{e.message}"
          return redirect_back_or_to import_admin_delivery_orders_path, alert: t("custom.errors.general_error")

        end

        unless maybe_error
          logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
          redirect_to admin_delivery_orders_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.delivery_order"))
          nil
        end

      else
        redirect_back_or_to import_admin_delivery_orders_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def delivery_order_params
        params.expect(delivery_order: [ :number, :purchase_order_id, :date, :warranty_expired, :description ])
      end

      def set_delivery_order
        @delivery_order = DeliveryOrder.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ASS_DO
      end

      def ensure_frame_response
        redirect_to admin_delivery_orders_path unless turbo_frame_request?
      end
  end
end
