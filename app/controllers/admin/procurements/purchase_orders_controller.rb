module Admin::Procurements
  class PurchaseOrdersController < ApplicationAdminController
    before_action :set_purchase_order, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :set_request_for_purchases, only: [ :show, :new, :create, :edit, :update ]

    def index
      authorize :authorization, :index?

      @q = PurchaseOrder.ransack(params[:q])
      @q.sorts = [ "date desc" ] if @q.sorts.empty?
      scope = @q.result.includes(:vendor, :request_for_purchase, :ship_to_site, :approved_by)
      @pagy, @purchase_orders = pagy(scope)
    end

    def show
      authorize :authorization, :read?
      @rfp_details = @purchase_order.request_for_purchase_details
    end

    def new
      authorize :authorization, :create?

      @purchase_order = PurchaseOrder.new
      @selected_details = []
    end

    def create
      authorize :authorization, :create?

      @purchase_order = PurchaseOrder.new(purchase_order_params)
      @purchase_order.date ||= Date.today.strftime("%Y-%m-%d")
      @selected_details = (params[:selected_details] || []).map(&:to_s)
      @request_for_purchase_details = RequestForPurchaseDetail.where(request_for_purchase_id: params[:purchase_order][:request_for_purchase_id])
      @purchase_order.currency = @request_for_purchase_details.first.currency unless @request_for_purchase_details.empty?
      @purchase_order.rate = @request_for_purchase_details.first.rate unless @request_for_purchase_details.empty?


      respond_to do |format|
        ActiveRecord::Base.transaction do
          if @purchase_order.save
            @selected_details.each do |selected_id|
              @purchase_order.request_for_purchase.request_for_purchase_details.find(selected_id).update_attribute(:purchase_order, @purchase_order)
            end
            amount_by_currency = @purchase_order.request_for_purchase_details.select(:qty, :price).sum { |detail| detail.price * detail.qty }
            amount_by_rate = amount_by_currency * @purchase_order.rate
            @purchase_order.update_attribute(:amount_by_currency, amount_by_currency)
            @purchase_order.update_attribute(:amount_by_rate, amount_by_rate)
            format.html { redirect_to admin_purchase_orders_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.purchase_order")) }
          else
            raise ActiveRecord::Rollback
          end
        end
        # format.html { render ("_form" if turbo_frame_request?), locals: { purchase_order: @purchase_order } }
        format.html { render :new, status: :unprocessable_entity }
      end
    end

    def edit
      authorize :authorization, :update?
      @purchase_order.date ||= Date.today.strftime("%Y-%m-%d")
      @selected_details = @purchase_order.request_for_purchase_details.pluck(:id).map { |id| id }

      rfp_details = @purchase_order.request_for_purchase_details
      unused_rfp_details = RequestForPurchaseDetail.where(request_for_purchase: @purchase_order.request_for_purchase, purchase_order: nil)
      @request_for_purchase_details = rfp_details + unused_rfp_details

      request_for_purchase_by_current_po = RequestForPurchase.find(@purchase_order.request_for_purchase.id)
      @request_for_purchases = @request_for_purchases.to_a
      @request_for_purchases << request_for_purchase_by_current_po
      @request_for_purchases = @request_for_purchases.uniq
    end

    def update
      authorize :authorization, :update?
      @selected_details = (params[:selected_details] || []).map(&:to_s)

      rfp_details = @purchase_order.request_for_purchase_details
      unused_rfp_details = RequestForPurchaseDetail.where(request_for_purchase: @purchase_order.request_for_purchase, purchase_order: nil)
      @request_for_purchase_details = rfp_details + unused_rfp_details

      request_for_purchase_by_current_po = RequestForPurchase.find(@purchase_order.request_for_purchase.id)
      @request_for_purchases = @request_for_purchases.to_a
      @request_for_purchases << request_for_purchase_by_current_po
      @request_for_purchases = @request_for_purchases.uniq

      prev_selected_details = @purchase_order.request_for_purchase_details.pluck(:id).map { |id| id }
      prev_request_for_purchase = @purchase_order.request_for_purchase

      respond_to do |format|
        ActiveRecord::Base.transaction do
          if @purchase_order.update(purchase_order_params)
            puts "PO INSPECT: #{@purchase_order.inspect}"


            # jika rfp nya berubah
            if @purchase_order.request_for_purchase != prev_request_for_purchase
              # loop dan lakukan update value kolom purchase_order_id pada request_for_purchase_details table sesuai dengan data yang di select
              @selected_details.each do |selected_id|
                @purchase_order.request_for_purchase.request_for_purchase_details.find(selected_id).update_attribute(:purchase_order, @purchase_order)
              end
              # kembalikan ke nil kolom purchase_order_id pada rfp yang sebelumnya di select
              # agar bisa digunakan kembali oleh PO yang lain
              prev_request_for_purchase.request_for_purchase_details.where(id: prev_selected_details).update_all(purchase_order_id: nil)
              amount_by_currency = @purchase_order.request_for_purchase_details.select(:qty, :price).sum { |detail| detail.price * detail.qty }
              amount_by_rate = amount_by_currency * @purchase_order.rate
              @purchase_order.update_attribute(:amount_by_currency, amount_by_currency)
              @purchase_order.update_attribute(:amount_by_rate, amount_by_rate)
            else
              # jika rfp nya tidak beruah
              # bandingkan details yang diselect, apakah masih sama atau ada perubahan
              if prev_selected_details.sort != @selected_details.sort
                # jika ada perubahan, update terlebih dahulu kolom purchase_order_id pada request_for_purchase_details sesuai rfp saat ini menjadi nil
                # ini mungkin masih bisa dioptimasi, tapi kita lihat nanti
                prev_request_for_purchase.request_for_purchase_details.where(id: prev_selected_details).update_all(purchase_order_id: nil)

                # loop semua details terbaru yang di select
                @selected_details.each do |selected_id|
                  # update kolom purchase_order_id sesuai detail selected terbaru
                  @purchase_order.request_for_purchase.request_for_purchase_details.find(selected_id).update_attribute(:purchase_order, @purchase_order)
                end

                @purchase_order.rate = @purchase_order.request_for_purchase_details.first.rate unless @purchase_order.request_for_purchase_details.empty?

                amount_by_currency = @purchase_order.request_for_purchase_details.select(:qty, :price).sum { |detail| detail.price * detail.qty }
                puts "AMOUNT BY CURRENCY: #{amount_by_currency}"
                puts "RATE: #{@purchase_order.inspect}"
                amount_by_rate = amount_by_currency * @purchase_order.rate
                @purchase_order.update_attribute(:amount_by_currency, amount_by_currency)
                @purchase_order.update_attribute(:amount_by_rate, amount_by_rate)
              end
            end

            format.html { redirect_to admin_purchase_orders_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.purchase_order")) }
          else
            raise ActiveRecord::Rollback
          end
        end

        format.html { render :edit, status: :unprocessable_entity }
      end
    end

    def destroy
      authorize :authorization, :destroy?
    end

    def destroy_many
      authorize :authorization, :destroy?

      purchase_order_ids = params[:purchase_order_ids]

      ActiveRecord::Base.transaction do
        purchase_orders = PurchaseOrder.where(id: purchase_order_ids)

        purchase_orders.each do |purchase_order|
          unless purchase_order.destroy
            error_message = purchase_order.errors.full_messages.join("")
            redirect_to admin_purchase_orders_path, alert: "#{error_message} - #{t('activerecord.models.purchase_order')} id: #{purchase_order.id_purchase_order}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_purchase_orders_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.purchase_order")) }
        end
      end
    end

    def load_rfp_details
      authorize :authorization, :create?

      purchase_order = PurchaseOrder.find(params[:po_id]) unless params[:po_id].blank?

      if purchase_order && purchase_order.persisted? && params[:id] == purchase_order.request_for_purchase.id
        rfp_details = purchase_order.request_for_purchase_details
        unused_rfp_details = RequestForPurchaseDetail.where(request_for_purchase: purchase_order.request_for_purchase, purchase_order: nil)
        @request_for_purchase_details = rfp_details + unused_rfp_details
      else
        @request_for_purchase_details = RequestForPurchaseDetail.where(request_for_purchase_id: params[:id], purchase_order: nil)
      end

      @selected_details = (params[:selected_details] || []).map(&:to_s)

      render turbo_stream: turbo_stream.replace(
        "rfp_details_table",
        partial: "admin/entries/purchase_orders/rfp_details_table",
        locals: { rfp_details: @request_for_purchase_details, selected_details: @selected_details })

      puts @request_for_purchase_details.inspect
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
          return redirect_back_or_to import_admin_purchase_orders_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        purchase_order_attributes_headers = {
          number: "Number",
          date: "Date",
          vendor: "Vendor id",
          request_for_purchase: "RFP number",
          amount_by_rate: "Amount by rate",
          currency: "Currency id",
          amount_by_currency: "Amount by currency",
          rate: "Rate",
          delivery_date: "Delivery date",
          ship_to_site: "Delivery to id",
          payment_remarks: "Payment remarks",
          approved_by: "Approved by id",
          description: "Description",
          status: "Status"

        }

        begin
          ActiveRecord::Base.transaction do
            sheet.parse(purchase_order_attributes_headers).each do |row|
              vendor = Vendor.find_by_id_vendor(row[:vendor]&.strip.upcase)
              rfp = RequestForPurchase.find_by_number(row[:request_for_purchase]&.strip)
              ship_to_site = PoDeliverySite.find_by_id_po_delivery_site(row[:ship_to_site]&.strip)
              approved_by = PersonalBoard.find_by_id_personal_board(row[:approved_by]&.strip)
              currency = Currency.find_by_id_currency(row[:currency]&.strip)

              if vendor.nil?
                maybe_error = true
                redirect_back_or_to import_admin_purchase_orders_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.vendor"), id: row[:vendor])
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:number]} - reason: vendor `#{row[:vendor]}` is not found"
                raise ActiveRecord::Rollback
                return
              end

              if rfp.nil?
                maybe_error = true
                redirect_back_or_to import_admin_purchase_orders_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.request_for_purchase"), id: row[:request_for_purchase])
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:number]} - reason: rfp `#{row[:request_for_purchase]}` is not found"
                raise ActiveRecord::Rollback
                return
              end

              if ship_to_site.nil?
                maybe_error = true
                redirect_back_or_to import_admin_purchase_orders_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.po_delivery_site"), id: row[:ship_to_site])
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:number]} - reason: Delivery to site `#{row[:ship_to_site]}` is not found"
                raise ActiveRecord::Rollback
                return
              end

              if approved_by.nil?
                maybe_error = true
                redirect_back_or_to import_admin_purchase_orders_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.personal_board"), id: row[:approved_by])
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:number]} - reason: approved by `#{row[:approved_by]}` is not found"
                raise ActiveRecord::Rollback
                return
              end

              if row[:currency].present?
                if currency.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_purchase_orders_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.currency"), id: row[:currency])
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:number]} - reason: currency #{row[:currency]} is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              data << {
                number: row[:number]&.strip,
                date: row[:date],
                vendor_id: vendor.id,
                request_for_purchase_id: rfp.id,
                amount_by_rate: row[:amount_by_rate],
                currency_id: currency&.id,
                amount_by_currency: row[:amount_by_currency],
                rate: row[:rate],
                delivery_date: row[:delivery_date],
                ship_to_site_id: ship_to_site.id,
                payment_remarks: row[:payment_remarks],
                approved_by_id: approved_by.id,
                status: row[:status],
                created_by: created_by,
                request_id: request_id,
                user_agent: user_agent,
                ip_address: ip_address
              }

              if data.size >= batch_size
                PurchaseOrder.insert_all!(data)
                data.clear
              end
            end

            PurchaseOrder.insert_all!(data) unless data.empty?
          end

        rescue Roo::HeaderRowNotFoundError => e
          redirect_to import_admin_purchase_orders_path, alert: t("custom.errors.invalid_import_template", errors: e)
          return


        # Penanganan untuk duplikat data
        rescue ActiveRecord::RecordNotUnique => e
          logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
          duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
          duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
          humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
          redirect_back_or_to import_admin_purchase_orders_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."
          return

        # penangan error null violation
        rescue ActiveRecord::NotNullViolation => e
          logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
          error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
          error_row = data.find { |r| r[error_column.to_sym].nil? }

          error_message = "#{t('activerecord.attributes.purchase_order.' + error_column)} " \
            "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
          redirect_back_or_to import_admin_purchase_orders_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"
          return

        # Penanganan umum untuk semua jenis error lainnya
        rescue => e
          logger.error "#{Current.request_id} - General error during import: #{e.message}"
          redirect_back_or_to import_admin_purchase_orders_path, alert: t("custom.errors.general_error")
          return

        end

        unless maybe_error
          logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
          redirect_to admin_purchase_orders_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.purchase_order"))
          nil
        end

      else
        redirect_back_or_to import_admin_purchase_orders_path, alert: t("custom.flash.alerts.select_file")
      end
    end

    private
      def purchase_order_params
        params.expect(purchase_order: [
          :number,
          :date,
          :vendor_id,
          :request_for_purchase_id,
          :delivery_date,
          :ship_to_site_id,
          :payment_remarks,
          :approved_by_id,
          :status
        ])
      end

      def set_purchase_order
        @purchase_order = PurchaseOrder.find(params[:id])
        @purchase_order.date = @purchase_order.date.strftime("%Y-%m-%d")
        @purchase_order.delivery_date = @purchase_order.delivery_date.strftime("%Y-%m-%d")
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_FINMGMT_PO
      end

      def set_request_for_purchases
        @request_for_purchases = RequestForPurchase
          .joins(:request_for_purchase_details)
          .where(request_for_purchase_details: { purchase_order: nil })
          .group("request_for_purchases.id")
      end
  end
end
