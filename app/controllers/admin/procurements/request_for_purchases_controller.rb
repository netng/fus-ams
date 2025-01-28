module Admin::Procurements
  class RequestForPurchasesController < ApplicationAdminController
    before_action :set_request_for_purchase, only: [ :edit, :update, :destroy ]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = RequestForPurchase.ransack(params[:q])
      @q.sorts = [ "date desc" ] if @q.sorts.empty?
      scope = @q.result.includes(:from_department, :to_department, :capital_proposal)
      @pagy, @request_for_purchases = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @request_for_purchase = RequestForPurchase.new

      if params[:add_rfp_details] == "add_rfp_details"
        @request_for_purchase.request_for_purchase_details.build
        @request_for_purchase.request_for_purchase_details.each do |rfp_detail|
          rfp_detail.tentative_date = Date.today
          rfp_detail.confirm_date = Date.today
        end
      end

      @request_for_purchase.date ||= Date.today.strftime("%Y-%m-%d")

      # render ("_form" if turbo_frame_request?), locals: { request_for_purchase: @request_for_purchase }
    end

    def create
      authorize :authorization, :create?

      @request_for_purchase = RequestForPurchase.new(request_for_purchase_params)
      @request_for_purchase.date ||= Date.today.strftime("%Y-%m-%d")


      puts @request_for_purchase.inspect

      respond_to do |format|
        if @request_for_purchase.save
          format.html { redirect_to admin_request_for_purchases_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.request_for_purchase")) }
        else
          # format.html { render ("_form" if turbo_frame_request?), locals: { request_for_purchase: @request_for_purchase } }
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
        begin
          @request_for_purchase.update(request_for_purchase_params)
          format.html { redirect_to admin_request_for_purchases_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.request_for_purchase")) }
        rescue ActiveRecord::RecordNotDestroyed => e
          logger.debug "ERROR => #{e.inspect}"
          format.html { render :edit, status: :unprocessable_entity }
        end
        # if @request_for_purchase.update(request_for_purchase_params)
        # 	format.html { redirect_to admin_request_for_purchases_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.request_for_purchase")) }
        # else
        # 	format.html { render :edit, status: :unprocessable_entity }
        # end
      end
    end

    def destroy
      authorize :authorization, :destroy?
    end

    def destroy_many
      authorize :authorization, :destroy?

      request_for_purchase_ids = params[:request_for_purchase_ids]

      ActiveRecord::Base.transaction do
        request_for_purchases = RequestForPurchase.where(id: request_for_purchase_ids)

        request_for_purchases.each do |request_for_purchase|
          unless request_for_purchase.destroy
            logger.debug "RFP Destroy error - #{request_for_purchase.errors.inspect}"
            error_message = request_for_purchase.errors.full_messages.join("")
            redirect_to admin_request_for_purchases_path, alert: "#{error_message} - #{t('activerecord.models.request_for_purchase')} id: #{request_for_purchase.number}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_request_for_purchases_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.request_for_purchase")) }
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
          return redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        request_for_purchase_attributes_headers = {
          number: "Number",
          capital_proposal: "Capital proposal number",
          from_department: "From department id",
          to_department: "To department id",
          date: "Date",
          material_code: "Material code",
          remarks: "Remarks",
          issued_by: "Issued by",
          authorized_by: "Authorized by",
          status: "Status"

        }

        begin
          ActiveRecord::Base.transaction do
            sheet.parse(request_for_purchase_attributes_headers).each do |row|
              from_department = Department.find_by_id_department(row[:from_department]&.strip)
              to_department = Department.find_by_id_department(row[:to_department]&.strip)
              capital_proposal = CapitalProposal.find_by_number(row[:capital_proposal]&.strip)

              if from_department.nil?
                # maybe_error = true
                # redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.activerecord_object_not_found", model: t("custom.label.from_department"), id: row[:from_department])
                # raise ActiveRecord::Rollback
                # return
                logger.debug "request_id: #{request.request_id} - RFP number: #{row[:number]} - reason: from_department id `#{row[:from_department]}` is not found"
                from_department = Department.create(
                  name: "#{row[:from_department].strip.upcase} (safety net)",
                  id_department: row[:from_department].strip.upcase

                )
              end

              if to_department.nil?
                # maybe_error = true
                logger.debug "request_id: #{request.request_id} - RFP number: #{row[:number]} - reason: to_department id `#{row[:to_department]}` is not found"
                # redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.activerecord_object_not_found", model: t("custom.label.to_department"), id: row[:to_department])
                # raise ActiveRecord::Rollback
                # return
                # # safety net jika po tidak ada namun pada file import dari fus-online po number tertulis ynag sebenernya po tidak ada di db fusonline, mungkin terhapus
                to_department = Department.create(
                  name: "#{row[:to_department].strip.upcase} (safety net)",
                  id_department: row[:to_department].strip.upcase

                )
              end

              if row[:capital_proposal].present?
                if capital_proposal.nil?
                  # maybe_error = true
                  # redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.capital_proposal"), id: row[:capital_proposal])
                  # raise ActiveRecord::Rollback
                  # return
                  #
                  # safety net
                  capital_proposal = CapitalProposal.create(
                    number: row[:capital_proposal]&.strip.upcase,
                    capital_proposal_type: CapitalProposalType.find_by_id_capital_proposal_type("safety-net"),
                    capital_proposal_group: CapitalProposalGroup.find_by_id_capital_proposal_group("safety-net"),
                    site: Site.find_by_id_site("safety-net"),
                    department: Department.find_by_id_department("safety-net"),
                    date: Date.today,
                    description: "safety net",
                    currency: Currency.first,
                    equiv_amount: 1,
                    rate: 1,
                    budget_ref_number: 1,
                    budget_amount: 1,
                    status: "Open"
                  )
                end
              end

              data << {
                number: row[:number]&.strip,
                capital_proposal_id: capital_proposal&.id,
                from_department_id: from_department.id,
                to_department_id: to_department.id,
                date: row[:date],
                material_code: row[:material_code],
                remarks: row[:remarks],
                issued_by: row[:issued_by],
                authorized_by: row[:authorized_by],
                status: row[:status],
                created_by: created_by,
                request_id: request_id,
                user_agent: user_agent,
                ip_address: ip_address
              }

              if data.size >= batch_size
                RequestForPurchase.insert_all!(data)
                data.clear
              end
            end

            RequestForPurchase.insert_all!(data) unless data.empty?
          end

        rescue Roo::HeaderRowNotFoundError => e
          return redirect_to import_admin_request_for_purchases_path, alert: t("custom.errors.invalid_import_template", errors: e)


        # Penanganan untuk duplikat data
        rescue ActiveRecord::RecordNotUnique => e
          logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
          duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
          duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
          humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
          return redirect_back_or_to import_admin_request_for_purchases_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

        # penangan error null violation
        rescue ActiveRecord::NotNullViolation => e
          logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
          error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
          error_row = data.find { |r| r[error_column.to_sym].nil? }

          error_message = "#{t('activerecord.attributes.request_for_purchase.' + error_column)} " \
            "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
          return redirect_back_or_to import_admin_request_for_purchases_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

        # Penanganan umum untuk semua jenis error lainnya
        rescue => e
          logger.error "#{Current.request_id} - General error during import: #{e.message}"
          return redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.general_error")

        end

        unless maybe_error
          logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
          redirect_to admin_request_for_purchases_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.request_for_purchase"))
          nil
        end

      else
        redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.flash.alerts.select_file")
      end
    end

    def process_import_details
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
          return redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        request_for_purchase_details_attributes_headers = {
          qty: "Qty",
          tentative_date: "Tentative date",
          confirm_date: "Confirm date",
          specs: "Specs",
          currency: "Currency id",
          rate: "Rate",
          request_for_purchase: "RFP number",
          price: "Price",
          sub_total: "Sub total",
          status: "Status",
          purchase_order: "PO number"
        }

        begin
          ActiveRecord::Base.transaction do
            sheet.parse(request_for_purchase_details_attributes_headers).each do |row|
              currency = Currency.find_by_id_currency(row[:currency]&.strip)
              rfp = RequestForPurchase.find_by_number(row[:request_for_purchase]&.strip)
              po = PurchaseOrder.find_by_number(row[:purchase_order]&.strip)

              if currency.nil?
                maybe_error = true
                redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.currency"), id: row[:currency])
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:request_for_purchase]} - reason: currency id `#{row[:currency]}` is not found"
                raise ActiveRecord::Rollback
                return
              end

              if rfp.nil?
                # maybe_error = true
                # redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.request_for_purchase"), id: row[:request_for_purchase])
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:request_for_purchase]} - reason: RFP number `#{row[:request_for_purchase]}` is not found"
                # raise ActiveRecord::Rollback
                # return

                # safety net ketika rfp tidak ada di db, untuk kepentingan import migrasi dari fus-online
                # jangan digunakan untuk selanjutnya
                rfp = RequestForPurchase.create(
                  number: row[:request_for_purchase]&.strip,
                  from_department: Department.find_by_id_department("safety-net"),
                  to_department: Department.find_by_id_department("safety-net"),
                  date: Date.today,
                  material_code: "safety net",
                  status: "Open"
                )
              end

              if row[:purchase_order].present?
                if po.nil?
                  # maybe_error = true
                  # redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.purchase_order"), id: row[:purchase_order])
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:request_for_purchase]} - reason: PO number `#{row[:purchase_order]}` is not found"
                  # raise ActiveRecord::Rollback
                  # return

                  # ini sama seperti rfp diatas
                  po = PurchaseOrder.create(
                    number: row[:purchase_order]&.strip,
                    date: Date.today,
                    vendor: Vendor.find_by_id_vendor("safety-net"),
                    request_for_purchase: rfp,
                    delivery_date: Date.today,
                    ship_to_site: PoDeliverySite.find_by_id_po_delivery_site("MD"),
                    payment_remarks: "safety net",
                    approved_by: PersonalBoard.find_by_id_personal_board("sf"),
                    status: "Open"
                  )
                end
              end

              data << {
                qty: row[:qty],
                tentative_date: row[:tentative_date],
                confirm_date: row[:confirm_date],
                specs: row[:specs],
                currency_id: currency.id,
                rate: row[:rate],
                request_for_purchase_id: rfp.id,
                price: row[:price],
                sub_total: row[:sub_total],
                status: row[:status],
                purchase_order_id: po&.id,
                created_by: created_by,
                request_id: request_id,
                user_agent: user_agent,
                ip_address: ip_address
              }

              if data.size >= batch_size
                RequestForPurchaseDetail.insert_all!(data)
                data.clear
              end
            end

            RequestForPurchaseDetail.insert_all!(data) unless data.empty?
          end

        rescue Roo::HeaderRowNotFoundError => e
          return redirect_to import_admin_request_for_purchases_path, alert: t("custom.errors.invalid_import_template", errors: e)


        # Penanganan untuk duplikat data
        rescue ActiveRecord::RecordNotUnique => e
          logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
          duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
          duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
          humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
          return redirect_back_or_to import_admin_request_for_purchases_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

        # penangan error null violation
        rescue ActiveRecord::NotNullViolation => e
          logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
          error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
          error_row = data.find { |r| r[error_column.to_sym].nil? }

          error_message = "#{t('activerecord.attributes.request_for_purchase.' + error_column)} " \
            "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
          return redirect_back_or_to import_admin_request_for_purchases_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

        # Penanganan umum untuk semua jenis error lainnya
        rescue => e
          logger.error "#{Current.request_id} - General error during import: #{e.message}"
          return redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.general_error")

        end

        unless maybe_error
          logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
          redirect_to admin_request_for_purchases_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.request_for_purchase"))
          nil
        end

      else
        redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def request_for_purchase_params
        params.expect(request_for_purchase: [
          :number,
          :capital_proposal_id,
          :from_department_id,
          :to_department_id,
          :date,
          :material_code,
          :remarks,
          :issued_by,
          :authorized_by,
          :status,
          request_for_purchase_details_attributes: [ [
            :id,
            :qty,
            :tentative_date,
            :confirm_date,
            :specs,
            :currency_id,
            :rate,
            :price,
            :_destroy
          ] ]
        ])
      end

      def set_request_for_purchase
        @request_for_purchase = RequestForPurchase.find(params[:id])
        @request_for_purchase.date = @request_for_purchase.date.strftime("%Y-%m-%d")
        if @request_for_purchase.request_for_purchase_details.present?
          @request_for_purchase.request_for_purchase_details.each do |rfp_detail|
            rfp_detail.rate = rfp_detail.rate.to_i unless rfp_detail.rate.nil?
            rfp_detail.price = rfp_detail.price.to_i unless rfp_detail.price.nil?
            rfp_detail.sub_total = rfp_detail.sub_total.to_i unless rfp_detail.sub_total.nil?
          end
        end
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_FINMGMT_RFP
      end
  end
end
