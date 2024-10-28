module Admin
  class RequestForPurchasesController < ApplicationAdminController
    before_action :set_request_for_purchase, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = RequestForPurchase.ransack(params[:q])
      @q.sorts = ["date desc"] if @q.sorts.empty?
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
          format.html { redirect_to admin_request_for_purchases_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.request_for_purchase"))}
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
				if @request_for_purchase.update(request_for_purchase_params)
					format.html { redirect_to admin_request_for_purchases_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.request_for_purchase")) }
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

      request_for_purchase_ids = params[:request_for_purchase_ids]

			ActiveRecord::Base.transaction do
				request_for_purchases = RequestForPurchase.where(id: request_for_purchase_ids)

				request_for_purchases.each do |request_for_purchase|
					unless request_for_purchase.destroy
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
      allowed_extension = [".xlsx", ".csv"]
      file = params[:file]
      data = []
      batch_size = 1000

      log = File.open("/home/hellodev/dev/fus/fus-ams/request_for_purchases_import_error_log.txt", "a")

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

              from_department = Department.find_by_id_department(row[:from_department])
              to_department = Department.find_by_id_department(row[:to_department])
              capital_proposal = CapitalProposal.find_by_number(row[:capital_proposal])

              if from_department.nil?
                # redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.activerecord_object_not_found", model: t("custom.label.from_department"), id: row[:from_department])
                # raise ActiveRecord::Rollback
                # return
                log.puts "From department id : #{row[:from_dapartment]} is not found"
                next
              end

              if to_department.nil?
                # redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.activerecord_object_not_found", model: t("custom.label.to_department"), id: row[:to_department])
                # raise ActiveRecord::Rollback
                # return
                log.puts "To department id : #{row[:to_dapartment]} is not found"
                next
              end

              if row[:capital_proposal].present?
                if capital_proposal.nil?
                  log.puts "Capital proposal number : #{row[:capital_proposal]} is not found"
                  # redirect_back_or_to import_admin_request_for_purchases_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.capital_proposal"), id: row[:capital_proposal])
                  # raise ActiveRecord::Rollback
                  next
                end
              end

              data << {
                number: row[:number],
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
          
          respond_to do |format|
            logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
            file.close()
            format.html { redirect_to admin_request_for_purchases_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.request_for_purchase")) }
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
          return redirect_back_or_to import_admin_request_for_purchases_path, alert: t('custom.errors.general_error')

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
          request_for_purchase_details_attributes: [[
            :id,
            :qty,
            :tentative_date,
            :confirm_date,
            :specs,
            :currency_id,
            :rate,
            :price,
            :_destroy
          ]]
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
				@function_access_code = FunctionAccessConstant::FA_ASS_CP
      end
  end
end