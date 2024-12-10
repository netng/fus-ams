module Admin::Entries
  class AssetsController < ApplicationAdminController
    before_action :set_asset, only: [
      :show, :edit, :update, :destroy,
      :edit_location, :update_location,
      :edit_software, :update_software
    ]

    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update, :edit_location, :export_confirm, :report_queues ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?
      @q = nil


      @ransack_params = ransack_params

      if current_account.site.site_default.blank?
        @q = Asset.joins(:site).where(sites: { id: current_account.site.id })
          .or(Asset.joins(:site).where(sites: { parent_site: current_account.site }))
          .ransack(ransack_params)

        @parent_sites = Site.where(id: current_account.site.id).pluck(:name, :id)
      else
        @q = Asset.ransack(ransack_params)
        @parent_sites = Site.where(parent_site_id: nil).pluck(:name, :id)
      end

      @q.sorts = [ "tagging_id asc" ] if @q.sorts.empty?
      scope = @q.result.includes(
        :project,
        :site,
        :asset_model,
        :asset_class,
        :delivery_order,
        :components,
        :softwares,
        :user_asset,
        asset_model: :brand,
      )

      if ransack_params && ransack_params[:site_id].present?
        site_id = params[:q][:site_id]

        site_ids = Site.where(id: site_id)
          .or(Site.where(parent_site_id: site_id))
          .pluck(:id)

        scope = scope.where(site_id: site_ids)
      end

      @pagy, @assets = pagy(scope)
    end

    def export_confirm
      @ransack_params = ransack_params
      authorize :authorization, :read?
    end
    def export
      authorize :authorization, :index?

      file_name = "asset_report_#{Time.now.strftime('%d-%m-%Y_%H_%M_%S_%s')}.xlsx"
      sheet_password = params[:sheet_password].strip

      if params[:file_name].blank?
        file_name
      else
        file_name = "#{params[:file_name]}_#{Time.now.strftime('%d-%m-%Y_%H_%M_%S_%s')}.xlsx"
      end
      logger.debug "FILE_NAME ======= #{file_name}"


      @q = nil

      if current_account.site.site_default.blank?
        @q = Asset.joins(:site).where(sites: { id: current_account.site.id })
          .or(Asset.joins(:site).where(sites: { parent_site: current_account.site }))
          .ransack(ransack_params)
      else
        @q = Asset.ransack(ransack_params)
      end

      @q.sorts = [ "tagging_id asc" ] if @q.sorts.empty?
      scope = @q.result.includes(
        :project,
        :site,
        :asset_model,
        :asset_class,
        :delivery_order,
        :components,
        :softwares,
        :user_asset,
        asset_model: :brand,
      )

      if params[:q] && params[:q][:site_id].present?
        site_id = params[:q][:site_id]

        site_ids = Site.where(id: site_id)
                       .or(Site.where(parent_site_id: site_id))
                       .pluck(:id)

        scope = scope.where(site_id: site_ids)
      end

      @pagy, @assets = pagy(scope)

      export_asset_job = ExportAssetJob.perform_later(current_account, ransack_params, file_name, sheet_password)
      puts "Export asset job: #{export_asset_job.job_id}"

      ReportQueue.create!(
        name: file_name,
        file_path: "-",
        generated_by: current_account,
        job_id: export_asset_job.job_id,
        created_by: current_account.username,
        ip_address: Current.ip_address,
        scheduled_at: Time.now
      )

      redirect_to admin_assets_path, notice: t("custom.flash.notices.report_queues")
    end

    def report_queues
      authorize :authorization, :read?

      @report_queues = current_account.report_queues.order(created_at: :desc)

      render "admin/entries/assets/report_queues/index"
    end

    def report_queues_destroy_many
      authorize :authorization, :destroy?

      report_queue_ids = params[:report_queue_ids]

      ActiveRecord::Base.transaction do
        report_queues = ReportQueue.where(id: report_queue_ids)

        report_queues.each do |report_queue|
          file_path = report_queue.file_path
          if report_queue.destroy
            FileUtils.remove_file(file_path)
          else
            error_message = report_queue.errors.full_messages.join("")
            redirect_to admin_report_queues_path, alert: "#{error_message} - #{t('activerecord.models.report_queue')} id: #{report_queue.id}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.turbo_stream do
            @report_queues = current_account.report_queues.order(created_at: :desc)
            render turbo_stream: turbo_stream.replace("report-queues", partial: "admin/entries/assets/report_queues/turbo_table", locals: { report_queues: @report_queues })
          end
        end
      end
    end

    def report_queues_download
      authorize :authorization, :read?

      report = ReportQueue.find(params[:report_id])
      logger.debug "=== REPORT PARAMS === : #{params[:report_id]}"

      if report && File.exist?(Rails.root.join(report.file_path))
        logger.debug "======== REPORT ======= #{report.inspect}"
        send_file report.file_path,
          type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          filename: report.name,
          disposition: "attachment"

        report.update(
          last_downloaded_by: current_account.username,
          last_downloaded_at: Time.now,
          download_count: report.download_count + 1
        )
      else
        redirect_to admin_assets_path, alert: "File not found"
      end
    end


    def show
      authorize :authorization, :read?

      # if turbo_frame_request? && turbo_frame_request_id == "second_modal"
      #   render "admin/entries/assets/show", layout: false
      # else
      #   render "admin/entries/assets/show"
      # end
    end

    def new
      authorize :authorization, :create?

      @asset = Asset.new

      @site_defaults = []
    end

    def create
      authorize :authorization, :create?

      @asset = Asset.new(asset_params)

      @asset.tagging_date = Date.today

      @asset.user_asset = UserAsset
        .find_by_id_user_asset(
          SiteDefault.find_by_site_id(@asset.site_id).id_user_site_default
          ) unless @asset.site_id.nil?

      set_site_default(@asset)

      respond_to do |format|
        if @asset.save
          format.html {
            redirect_to admin_assets_path,
            notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.asset"))
          }
        else
          puts @asset.errors.messages
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize :authorization, :update?

      set_site_default(@asset)
    end

    def update
      authorize :authorization, :update?

      set_site_default(@asset)

      # Filter asset_components yang valid berdasarkan component_id yang ada
      # Jika component_id blank, tandai untuk dihapus dari asset_components
      params[:asset][:asset_components_attributes]&.each do |key, component_params|
        if component_params[:component_id].blank?
          component_params[:_destroy] = "1"
        end
      end

      respond_to do |format|
        if @asset.update(asset_params)
          format.html {
            redirect_to admin_assets_path,
            notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset"))
          }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def edit_location
      authorize :authorization, :update?

      @q = UserAsset.ransack(params[:q])
      @q.sorts = [ "id_user_asset asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:site, :department)
      @pagy, @user_assets = pagy(scope, limit: 5)

      if params[:q].present?
        respond_to do |format|
          format.turbo_stream do
            logger.debug "TURBO STREAM RENDER"
            render turbo_stream: turbo_stream.replace(
              "table_user_assets",
              partial: "admin/entries/assets/user_assets/turbo_table",
              locals: { user_assets: @user_assets, pagy: @pagy }
            )
          end
          format.html do
            logger.debug "fallback render"
            render partial: "admin/entries/assets/user_assets/turbo_table",
                   locals: { user_assets: @user_assets, pagy: @pagy }
          end
        end
      else
        # Permintaan awal: render view edit_location.html.erb
        logger.debug "first render"
        render :edit_location
      end
    end

    def update_location
      authorize :authorization, :update?

      @q = UserAsset.ransack(params[:q])
      @q.sorts = [ "id_user_asset asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:site, :department)
      @pagy, @user_assets = pagy(scope, limit: 5)

      user_asset_id = params[:user_asset_id]
      user_asset = UserAsset.find_by_id(user_asset_id)

      respond_to do |format|
        if user_asset && @asset.update(user_asset: user_asset, site: user_asset.site)
          format.html {
            redirect_to admin_assets_path,
            notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset"))
          }
        else
          format.html {
            redirect_to admin_assets_path,
            alert: t("custom.flash.alerts.user_asset_is_not_found")
          }
        end
      end
    end

    def edit_software
      authorize :authorization, :update?
      @asset_softwares = @asset.asset_softwares
    end

    def update_software
      authorize :authorization, :update?

      params[:asset][:asset_softwares_attributes]&.each do |key, software_params|
        if software_params[:software_id].blank?
          software_params[:_destroy] = "1"
        end
      end

      respond_to do |format|
        if @asset.update(asset_params)
          format.html {
            redirect_to admin_assets_path,
            notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset"))
          }
        else
          puts @asset.errors.messages
          format.html { render :edit_software, status: :unprocessable_entity }
        end
      end
    end

    # kode ini tidak dipakai
    # sudah dipindah ke edit_location
    # supaya tidak beda action
    # kita biarkan kode ini untuk archive
    # def search_user_assets
    #   authorize :authorization, :update?

    #   @q = UserAsset.ransack(params[:q])
    #   @q.sorts = [ "id_user_asset asc" ] if @q.sorts.empty?
    #   @user_assets = @q.result.includes(:site, :department)
    #   @pagy, @user_assets = pagy(@user_assets, limit: 5)

    #   respond_to do |format|
    #     format.turbo_stream do
    #       render turbo_stream: turbo_stream.replace(
    #         "table_user_assets",
    #         partial: "admin/entries/assets/user_assets/turbo_table",
    #         locals: { user_assets: @user_assets, pagy: @pagy }
    #       )
    #     end

    #     format.html do
    #       render partial: "admin/entries/assets/user_assets/turbo_table",
    #              locals: { user_assets: @user_assets, pagy: @pagy }
    #     end
    #   end
    # end

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
            error_message = asset.errors.full_messages.join("")
            redirect_to admin_assets_path, alert: "#{error_message} - #{t('activerecord.models.asset')} id: #{asset.number}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html {
            redirect_to admin_assets_path,
            notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.asset"))
          }
        end
      end
    end

    def site_default
      authorize :authorization, :read?

      if params[:query].present?
        query = params[:query].downcase

        site_defaults = Site
          .joins(site_default: { site: { site_group: :project } })
          .where(projects: { id: query })

        render json: site_defaults.pluck(:id, :name).map { |id, name| { id: id, name: name } }
      else
        render json: []
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

    def import_download_template
      authorize :authorization, :create?

      template_path = Rails.root.join("public", "templates", "asset-import.xlsx")

      package = Axlsx::Package.new
      wb = package.workbook

      s = wb.styles
      bold_text = s.add_style b: true
      header = s.add_style b: true, bg_color: "000080", fg_color: "ffffff", alignment: { vertical: :center }

      wb.add_worksheet(name: "Upload") do |sheet|
        sheet.add_row [
          "Tagging id",
          "Project id",
          "Site id",
          "Asset model id",
          "Asset class id",
          "DO number",
          "Warranty expired date",
          "Computer name",
          "IP computer",
          "CPU sn",
          "Monitor sn",
          "Keyboard sn",
          "Shipping date",
          "Description",
          "Mouse id",
          "Floopy disk id",
          "Processor id",
          "Memory id",
          "Hardisk id",
          "CD / DVD rom id",
          "NIC id",
          "Others id"
        ], style: header
      end

      wb.add_worksheet(name: "Panduan") do |sheet|
        sheet.add_row [ "Panduan upload" ]
        sheet.add_row [ "1. Tagging id harus diisi dan unik (tidak boleh sama)" ]
        sheet.add_row [ "2. Row Project id, Site id, Asset model id, Asset class id diisi dengan id masing-masing. Id bisa dicek pada masing-masing sheet sesuai nama row" ]
        sheet.add_row [ "3. Row Project id, Site id, Asset model id wajib diisi" ]
        sheet.add_row [ "4. Row Mouse id, Floopy disk id, Processor id, Memory id, Hardisk id, CD / DVD room id, NIC id, Other id diisi dengan id masing-masing. Id bisa dicek pada sheet `Components ID`" ]
      end

      wb.add_worksheet(name: "Project ID") do |sheet|
        sheet.add_row [ "Project id", "Name" ], style: header

        Project.all.each do |project|
          sheet.add_row [
            project.id_project,
            project.name
          ]
        end
      end

      wb.add_worksheet(name: "Site ID") do |sheet|
        sheet.add_row [ "Site id", "Name" ], style: header

        Site.all.each do |site|
          sheet.add_row [
            site.id_site,
            site.name
          ]
        end
      end

      wb.add_worksheet(name: "Asset Model ID") do |sheet|
        sheet.add_row [ "Asset model id", "Name" ], style: header

        AssetModel.all.each do |asset_model|
          sheet.add_row [
            asset_model.id_asset_model,
            asset_model.name
          ]
        end
      end

      wb.add_worksheet(name: "Component ID") do |sheet|
        sheet.add_row [ "Component id", "Name", "Component type" ], style: header
        components = Component.includes(:component_type).order("component_types.name ASC")

        components.each do |component|
          sheet.add_row [
            component.id_component,
            component.name,
            component.component_type.name
          ]
        end
      end

      package.serialize(template_path)


      send_file template_path,
          type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          filename: "asset-import.xlsx",
          disposition: "attachment"
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
          ] ],
          asset_softwares_attributes: [ [
            :id,
            :sequence_number,
            :software_id,
            :license,
            :_destroy
          ] ]
        ])
      end

      def ransack_params
        params.fetch(:q, {}).permit(
          :tagging_id_cont,
          :site_id,
          :site_site_group_id_eq,
          :site_site_stat_id_eq,
          :asset_model_id_eq,
          :asset_model_asset_type_id_eq,
          :asset_model_brand_id_eq,
          :delivery_order_number_cont,
          :project_id_eq,
          :components_id_eq,
          :softwares_id_eq,
          :monitor_sn_cont,
          :keyboard_sn_cont,
          :computer_name_cont,
          :user_asset_username_cont,
          :s
        )
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
        @previous_url = request.referer || admin_assets_path || root_path
      end

      def set_site_default(asset)
        @site_defaults = Site
          .joins(site_default: { site: { site_group: :project } })
          .where(projects: { id: @asset.project_id })
          .pluck(:id, :name)
          .map { |id, name| [ name, id ] } || []
      end
  end
end
