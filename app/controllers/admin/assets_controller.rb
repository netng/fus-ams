module Admin
  class AssetsController < ApplicationAdminController
    before_action :set_asset, only: [ :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :new, :create, :edit, :update ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?

      @q = Asset.ransack(params[:q])
      @q.sorts = [ "tagging_id asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:project, :site, :asset_model, :asset_class, :delivery_order)
      @pagy, @assets = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @asset = Asset.new
      8.times { @asset.asset_components.build }
      @site_defaults = []
    end

    def site_default
      authorize :authorization, :read?

      if params[:query].present?
        query = params[:query].downcase
        site_defaults = Site.joins(site_default: { site: { site_group: :project } }).where(projects: { id: query })
        render json: site_defaults.pluck(:id, :name).map { |id, name| { id: id, name: name } }
      else
        render json: []
      end
    end

    def create
      authorize :authorization, :create?

      @asset = Asset.new(asset_params)
      @asset.tagging_date = Date.today
      @asset.user_asset = UserAsset.find_by_id_user_asset(SiteDefault.find_by_site_id(@asset.site_id).id_user_site_default) unless @asset.site_id.nil?
      @site_defaults = Site.joins(site_default: { site: { site_group: :project } }).where(projects: { id: @asset.project_id }).pluck(:id, :name).map { |id, name| [ name, id ] } || []
      @selected_components = params[:selected_components]&.map(&:to_s) || []

      (8 - @asset.asset_components.size).times { @asset.asset_components.build }

      valid_components = @asset.asset_components.select { |component| component.component_id.present? }
      @asset.asset_components = valid_components
      puts @asset.asset_components.inspect

      respond_to do |format|
        if @asset.save
          format.html { redirect_to admin_assets_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.asset")) }
        else
          puts @asset.errors.messages
          # format.html { render ("_form" if turbo_frame_request?), locals: { asset: @asset } }
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize :authorization, :update?
      @site_defaults = Site.joins(site_default: { site: { site_group: :project } }).where(projects: { id: @asset.project_id }).pluck(:id, :name).map { |id, name| [ name, id ] } || []
      @asset.asset_components = @asset.asset_components.joins(component: :component_type).order("component_types.id_component_type ASC")

      puts @asset.asset_components.inspect

      # Pastikan jumlah asset_components adalah 8, jika kurang, tambahkan yang kosong
      while @asset.asset_components.size < 8
        # Dapatkan component_type berdasarkan urutan yang sudah ada
        next_available_type = ComponentType.where.not(id_component_type: @asset.asset_components.map { |ac| ac.component.component_type.id }).first
        if next_available_type
          @asset.asset_components.build(component: next_available_type.components.first) # Buat asset_component baru dengan component yang sesuai
        end
      end

      # (8 - @asset.asset_components.size).times { @asset.asset_components.build }
    end

    def update
      authorize :authorization, :update?
      @site_defaults = Site.joins(site_default: { site: { site_group: :project } }).where(projects: { id: @asset.project_id }).pluck(:id, :name).map { |id, name| [ name, id ] } || []
      (8 - @asset.asset_components.size).times { @asset.asset_components.build }

      respond_to do |format|
        begin
          @asset.update(asset_params)
          format.html { redirect_to admin_assets_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset")) }
        rescue ActiveRecord::RecordNotDestroyed => e
          logger.debug "ERROR => #{e.inspect}"
          format.html { render :edit, status: :unprocessable_entity }
        end
        # if @asset.update(asset_params)
        # 	format.html { redirect_to admin_assets_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset")) }
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

      asset_ids = params[:asset_ids]

      ActiveRecord::Base.transaction do
        assets = Asset.where(id: asset_ids)

        assets.each do |asset|
          unless asset.destroy
            logger.debug "RFP Destroy error - #{asset.errors.inspect}"
            error_message = asset.errors.full_messages.join("")
            redirect_to admin_assets_path, alert: "#{error_message} - #{t('activerecord.models.asset')} id: #{asset.number}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_assets_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.asset")) }
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
          return redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        asset_attributes_headers = {
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
            sheet.parse(asset_attributes_headers).each do |row|
              from_department = Department.find_by_id_department(row[:from_department]&.strip)
              to_department = Department.find_by_id_department(row[:to_department]&.strip)
              capital_proposal = CapitalProposal.find_by_number(row[:capital_proposal]&.strip)

              if from_department.nil?
                maybe_error = true
                redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("custom.label.from_department"), id: row[:from_department])
                raise ActiveRecord::Rollback
                return
              end

              if to_department.nil?
                maybe_error = true
                redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("custom.label.to_department"), id: row[:to_department])
                raise ActiveRecord::Rollback
                return
              end

              if row[:capital_proposal].present?
                if capital_proposal.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.capital_proposal"), id: row[:capital_proposal])
                  raise ActiveRecord::Rollback
                  return
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
                Asset.insert_all!(data)
                data.clear
              end
            end

            Asset.insert_all!(data) unless data.empty?
          end

        rescue Roo::HeaderRowNotFoundError => e
          return redirect_to import_admin_assets_path, alert: t("custom.errors.invalid_import_template", errors: e)


        # Penanganan untuk duplikat data
        rescue ActiveRecord::RecordNotUnique => e
          logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
          duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
          duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
          humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
          return redirect_back_or_to import_admin_assets_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

        # penangan error null violation
        rescue ActiveRecord::NotNullViolation => e
          logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
          error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
          error_row = data.find { |r| r[error_column.to_sym].nil? }

          error_message = "#{t('activerecord.attributes.asset.' + error_column)} " \
            "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
          return redirect_back_or_to import_admin_assets_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

        # Penanganan umum untuk semua jenis error lainnya
        rescue => e
          logger.error "#{Current.request_id} - General error during import: #{e.message}"
          return redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.general_error")

        end

        unless maybe_error
          logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
          redirect_to admin_assets_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset"))
          nil
        end

      else
        redirect_back_or_to import_admin_assets_path, alert: t("custom.flash.alerts.select_file")
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
          return redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        asset_details_attributes_headers = {
          qty: "Qty",
          tentative_date: "Tentative date",
          confirm_date: "Confirm date",
          specs: "Specs",
          currency: "Currency id",
          rate: "Rate",
          asset: "RFP number",
          price: "Price",
          sub_total: "Sub total",
          status: "Status",
          purchase_order: "PO number"
        }

        begin
          ActiveRecord::Base.transaction do
            sheet.parse(asset_details_attributes_headers).each do |row|
              currency = Currency.find_by_id_currency(row[:currency]&.strip)
              rfp = Asset.find_by_number(row[:asset]&.strip)
              po = PurchaseOrder.find_by_number(row[:purchase_order]&.strip)

              if currency.nil?
                maybe_error = true
                redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.currency"), id: row[:currency])
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:asset]} - reason: currency id `#{row[:currency]}` is not found"
                raise ActiveRecord::Rollback
                return
              end

              if rfp.nil?
                maybe_error = true
                redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset"), id: row[:asset])
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:asset]} - reason: RFP number `#{row[:asset]}` is not found"
                raise ActiveRecord::Rollback
                return

                # safety net ketika rfp tidak ada di db, untuk kepentingan import migrasi dari fus-online
                # jangan digunakan untuk selanjutnya
                # rfp = Asset.create(
                #   number: row[:asset]&.strip,
                #   from_department: Department.find_by_id_department("safety-net"),
                #   to_department: Department.find_by_id_department("safety-net"),
                #   date: Date.today,
                #   material_code: "safety net",
                #   status: "Open"
                # )
              end

              if row[:purchase_order].present?
                if po.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.purchase_order"), id: row[:purchase_order])
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:asset]} - reason: PO number `#{row[:purchase_order]}` is not found"
                  raise ActiveRecord::Rollback
                  return

                  # ini sama seperti rfp diatas
                  # po = PurchaseOrder.create(
                  #   number: row[:purchase_order]&.strip,
                  #   date: Date.today,
                  #   vendor: Vendor.find_by_id_vendor("safety-net"),
                  #   asset: rfp,
                  #   delivery_date: Date.today,
                  #   ship_to_site: PoDeliverySite.find_by_id_po_delivery_site("MD"),
                  #   payment_remarks: "safety net",
                  #   approved_by: PersonalBoard.find_by_id_personal_board("sf"),
                  #   status: "Open"
                  # )
                end
              end

              data << {
                qty: row[:qty],
                tentative_date: row[:tentative_date],
                confirm_date: row[:confirm_date],
                specs: row[:specs],
                currency_id: currency.id,
                rate: row[:rate],
                asset_id: rfp.id,
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
                AssetDetail.insert_all!(data)
                data.clear
              end
            end

            AssetDetail.insert_all!(data) unless data.empty?
          end

        rescue Roo::HeaderRowNotFoundError => e
          return redirect_to import_admin_assets_path, alert: t("custom.errors.invalid_import_template", errors: e)


        # Penanganan untuk duplikat data
        rescue ActiveRecord::RecordNotUnique => e
          logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
          duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
          duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
          humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
          return redirect_back_or_to import_admin_assets_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

        # penangan error null violation
        rescue ActiveRecord::NotNullViolation => e
          logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
          error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
          error_row = data.find { |r| r[error_column.to_sym].nil? }

          error_message = "#{t('activerecord.attributes.asset.' + error_column)} " \
            "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
          return redirect_back_or_to import_admin_assets_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

        # Penanganan umum untuk semua jenis error lainnya
        rescue => e
          logger.error "#{Current.request_id} - General error during import: #{e.message}"
          return redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.general_error")

        end

        unless maybe_error
          logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
          redirect_to admin_assets_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset"))
          nil
        end

      else
        redirect_back_or_to import_admin_assets_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def asset_params
        params.expect(asset: [
          :tagging_id,
          :project_id,
          :site_id,
          :asset_model_id,
          :asset_class_id,
          :computer_name,
          :computer_ip,
          :cpu_sn,
          :monitor_sn,
          :keyboard_sn,
          :delivery_order_id,
          :shipping_date,
          :description,
          asset_components_attributes: [ [
            :id,
            :component_id,
            :serial_number,
            :_destroy
          ] ]
        ])
      end

      def set_asset
        @asset = Asset.find(params[:id])
        @asset.tagging_date = @asset.tagging_date.strftime("%Y-%m-%d")
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ASSET
      end

      def ensure_frame_response
        redirect_to admin_assets_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = admin_assets_path || root_path
      end
  end
end
