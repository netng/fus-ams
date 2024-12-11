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
      @previous_url = admin_assets_path || root_path
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

        assets_attributes_headers = {
          tagging_id: "Tagging id *",
          project_id: "Project id *",
          site_id: "Site id *",
          asset_model_id: "Asset model id *",
          asset_class_id: "Asset class id",
          delivery_order_number: "DO number",
          computer_name: "Computer name",
          computer_ip: "Computer IP",
          cpu_sn: "CPU sn",
          monitor_sn: "Monitor sn",
          keyboard_sn: "Keyboard sn",
          shipping_date: "Shipping date",
          description: "Description",
          mouse_id: "Mouse id",
          mouse_sn: "Mouse sn",
          floopy_disk_id: "Floopy disk id",
          floopy_disk_sn: "Floopy disk sn",
          processor_id: "Processor id",
          processor_sn: "Processor sn",
          memory_id: "Memory id",
          memory_sn: "Memory sn",
          hardisk_id: "Hardisk id",
          hardisk_sn: "Hardisk sn",
          cd_dvd_rom_id: "CD / DVD rom id",
          cd_dvd_rom_sn: "CD / DVD rom sn",
          nic_id: "NIC id",
          nic_sn: "NIC sn",
          others_id: "Others id",
          other_sn: "Others sn"
        }

        begin
          ActiveRecord::Base.transaction do
            sheet.parse(assets_attributes_headers).each_with_index do |row, index|
              project = Project.find_by_id_project(row[:project_id]&.strip)
              site = Site.find_by_id_site(row[:site_id]&.strip)
              asset_model = AssetModel.find_by_id_asset_model(row[:asset_model_id]&.strip)
              asset_class = AssetClass.find_by_id_asset_class(row[:asset_class_id]&.strip)
              delivery_order = DeliveryOrder.find_by_number(row[:delivery_order_number]&.strip)
              comp_mouse = Component.find_by_id_component(row[:mouse_id]&.strip)
              comp_floopy_disk = Component.find_by_id_component(row[:floopy_disk_id]&.strip)
              comp_processor = Component.find_by_id_component(row[:processor_id]&.strip)
              comp_memory = Component.find_by_id_component(row[:memory_id]&.strip)
              comp_hardisk = Component.find_by_id_component(row[:hardisk_id]&.strip)
              comp_cd_dvd_rom = Component.find_by_id_component(row[:cd_dvd_rom_id]&.strip)
              comp_nic = Component.find_by_id_component(row[:nic_id]&.strip)
              comp_others = Component.find_by_id_component(row[:others_id]&.strip)
              asset = Asset.find_by_tagging_id(row[:tagging_id]&.strip)

              if row[:tagging_id].nil?
                maybe_error = true
                redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.record_required", record: "Tagging id", row_index: index + 1)
                logger.debug "request_id: #{request.request_id} - row index: #{index + 1} - reason: tagging id is empty"
                raise ActiveRecord::Rollback
                return
              end

              if asset.present?
                maybe_error = true
                redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.duplicate_data", field: "Tagging id", value: row[:tagging_id])
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: asset with tagging id `#{row[:tagging_id]}` already exists"
                raise ActiveRecord::Rollback
                return
              end

              if project.nil?
                maybe_error = true
                redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.project"), id: row[:project_id], row_index: index + 1)
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: project id `#{row[:project_id]}` is not found"
                raise ActiveRecord::Rollback
                return
              end

              if site.nil?
                maybe_error = true
                redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.site"), id: row[:site_id], row_index: index + 1)
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: site id `#{row[:site_id]}` is not found"
                raise ActiveRecord::Rollback
                return
              end

              if asset_model.nil?
                maybe_error = true
                redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_model"), id: row[:asset_model_id], row_index: index + 1)
                logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: asset_model id `#{row[:asset_model_id]}` is not found"
                raise ActiveRecord::Rollback
                return
              end

              if row[:asset_class_id].present?
                if asset_class.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_class"), id: row[:asset_class_id], row_index: index + 1)
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: asset class id `#{row[:asset_class_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              if row[:delivery_order_number].present?
                if delivery_order.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.delivery_order"), id: row[:delivery_order_id], row_index: index + 1)
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: delivery order id `#{row[:delivery_order_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              if row[:mouse_id].present?
                if comp_mouse.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_component"), id: row[:mouse_id], row_index: index + 1)
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: component mouse id `#{row[:mouse_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              if row[:floopy_disk_id].present?
                if comp_floopy_disk.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_component"), id: row[:floopy_disk_id]), row_index: index + 1
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: component floopy disk id `#{row[:floopy_disk_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              if row[:processor_id].present?
                if comp_processor.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_component"), id: row[:processor_id], row_index: index + 1)
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: component processor id `#{row[:processor_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              if row[:memory_id].present?
                if comp_memory.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_component"), id: row[:memory_id], row_index: index + 1)
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: component memory id `#{row[:memory_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              if row[:hardisk_id].present?
                if comp_hardisk.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_component"), id: row[:hardisk_id], row_index: index + 1)
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: component hardisk id `#{row[:hardisk_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              if row[:cd_dvd_rom_id].present?
                if comp_cd_dvd_rom.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_component"), id: row[:cd_dvd_rom_id], row_index: index + 1)
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: component cd/dvd rom id `#{row[:cd_dvd_rom_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              if row[:nic_id].present?
                if comp_nic.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_component"), id: row[:nic_id], row_index: index + 1)
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: component nic id `#{row[:nic_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              if row[:others_id].present?
                if comp_others.nil?
                  maybe_error = true
                  redirect_back_or_to import_admin_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_component"), id: row[:others_id], row_index: index + 1)
                  logger.debug "request_id: #{request.request_id} - data_id: #{row[:tagging_id]} - reason: component others id `#{row[:others_id]}` is not found"
                  raise ActiveRecord::Rollback
                  return
                end
              end

              user_asset_default = UserAsset
                .find_by_id_user_asset(
                  SiteDefault.find_by_site_id(site.id).id_user_site_default
                  ) unless site.nil?

              data << {
                tagging_date: Time.now,
                user_asset_id: user_asset_default&.id,
                tagging_id: row[:tagging_id].strip.upcase,
                project_id: project&.id,
                site_id: site&.id,
                asset_model_id: asset_model&.id,
                asset_class_id: asset_class&.id,
                delivery_order_id: delivery_order&.id,
                computer_name: row[:computer_name],
                computer_ip: row[:computer_ip],
                cpu_sn: row[:cpu_sn],
                monitor_sn: row[:monitor_sn],
                keyboard_sn: row[:keyboard_sn],
                shipping_date: row[:shipping_date],
                description: row[:description],
                created_by: created_by,
                request_id: request_id,
                user_agent: user_agent,
                ip_address: ip_address,
                asset_components: [
                  AssetComponent.new(component_id: comp_mouse&.id, serial_number: row[:mouse_sn]),
                  AssetComponent.new(component_id: comp_floopy_disk&.id, serial_number: row[:floopy_disk_sn]),
                  AssetComponent.new(component_id: comp_processor&.id, serial_number: row[:processor_sn]),
                  AssetComponent.new(component_id: comp_memory&.id, serial_number: row[:memory_sn]),
                  AssetComponent.new(component_id: comp_hardisk&.id, serial_number: row[:hardisk_sn]),
                  AssetComponent.new(component_id: comp_cd_dvd_rom&.id, serial_number: row[:cd_dvd_rom_sn]),
                  AssetComponent.new(component_id: comp_nic&.id, serial_number: row[:nic_sn]),
                  AssetComponent.new(component_id: comp_others&.id, serial_number: row[:others_sn])
                ]
              }

              Asset.create!(data)
              data.clear
            end
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
          respond_to do |format|
            format.turbo_stream do
              flash[:notice] = t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset"))
              render turbo_stream: turbo_stream.replace("flash-message", partial: "shared/flash")
            end

            format.html { redirect_to admin_assets_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset")) }
          end
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
      header = s.add_style b: true, bg_color: "000080", fg_color: "ffffff", alignment: { vertical: :center }

      wb.add_worksheet(name: "Upload") do |sheet|
        sheet.add_row [
          "Tagging id *",
          "Project id *",
          "Site id *",
          "Asset model id *",
          "Asset class id",
          "DO number",
          "Computer name",
          "Computer IP",
          "CPU sn",
          "Monitor sn",
          "Keyboard sn",
          "Shipping date",
          "Description",
          "Mouse id",
          "Mouse sn",
          "Floopy disk id",
          "Floopy disk sn",
          "Processor id",
          "Processor sn",
          "Memory id",
          "Memory sn",
          "Hardisk id",
          "Hardisk sn",
          "CD / DVD rom id",
          "CD / DVD rom sn",
          "NIC id",
          "NIC sn",
          "Others id",
          "Others sn"
        ], style: header

        sheet.sheet_view.pane do |pane|
          pane.state = :frozen
          pane.y_split = 1
        end
      end

      wb.add_worksheet(name: "Panduan") do |sheet|
        sheet.add_row [ "Panduan upload" ], style: header
        sheet.add_row [ "1. Lengkapi semua data-data yang ada pada sheet Upload" ]
        sheet.add_row [ "2. Kolom pada sheet Upload dengan simbol (*) artinya wajib diisi" ]
        sheet.add_row [ "3. Tagging id harus unik (tidak boleh sama)" ]
        sheet.add_row [ "4. Kolom Project id, Site id, Asset model id, Asset class id diisi dengan id masing-masing. Id bisa dicek pada masing-masing sheet sesuai nama kolom" ]
        sheet.add_row [ "5. Kolom Mouse id, Floopy disk id, Processor id, Memory id, Hardisk id, CD / DVD room id, NIC id, Other id diisi dengan id masing-masing. Id bisa dicek pada sheet `Components ID`" ]
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

      wb.add_worksheet(name: "Asset Class ID") do |sheet|
        sheet.add_row [ "Asset class id", "Name" ], style: header

        AssetClass.all.each do |asset_class|
          sheet.add_row [
            asset_class.id_asset_class,
            asset_class.name
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
