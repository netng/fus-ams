module Admin
  class AssetsController < ApplicationAdminController
    before_action :set_asset, only: [
      :edit, :update, :destroy,
      :edit_location, :update_location,
      :edit_software, :update_software
    ]

    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :new, :create, :edit, :update, :edit_location ]
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
              partial: "admin/assets/user_assets/turbo_table",
              locals: { user_assets: @user_assets, pagy: @pagy }
            )
          end
          format.html do
            logger.debug "fallback render"
            render partial: "admin/assets/user_assets/turbo_table",
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
    #         partial: "admin/assets/user_assets/turbo_table",
    #         locals: { user_assets: @user_assets, pagy: @pagy }
    #       )
    #     end

    #     format.html do
    #       render partial: "admin/assets/user_assets/turbo_table",
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

      def set_site_default(asset)
        @site_defaults = Site
          .joins(site_default: { site: { site_group: :project } })
          .where(projects: { id: @asset.project_id })
          .pluck(:id, :name)
          .map { |id, name| [ name, id ] } || []
      end
  end
end
