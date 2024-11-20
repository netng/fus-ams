module Admin::Entries
  class UserAssetsController < ApplicationAdminController
    before_action :set_user_asset, only: [ :show, :edit, :update, :destroy, :assets ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update, :assets ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?

      @q = UserAsset.ransack(params[:q])
      @q.sorts = [ "id_user_asset asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:site, :department)
      @pagy, @user_assets = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @user_asset = UserAsset.new
    end

    def create
      authorize :authorization, :create?

      @user_asset = UserAsset.new(user_assets_params)


      # Note:
      # Original query dari fus-online untuk generate id_user_asset
      #
      # select 'U-' + cast(max(Cast(Substring(UserId,3,10) as int))+1 as nvarchar(28))
      # from MstAssetUser
      # where UserId not in (select Distinct UserId from SiteDefault);
      #
      # query dibawah ini penyesuaian menggunakan activerecord dan postgres
      subquery = SiteDefault.select(:id_user_site_default).distinct
      result = UserAsset
        .where.not(id_user_asset: subquery)
        .pluck(Arel.sql("'U-' || CAST(MAX(CAST(SUBSTRING(id_user_asset, 3, 10) AS INT)) + 1 AS VARCHAR(28)) AS next_user_id"))

      @user_asset.id_user_asset = result.first

      logger.info "request_id: #{request.request_id} - #{@user_asset.id_user_asset}"

      respond_to do |format|
        if @user_asset.save
          format.html { redirect_to admin_user_assets_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.user_asset")) }
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
        if @user_asset.update(user_assets_params)
          format.html { redirect_to admin_user_assets_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.user_asset")) }
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

      user_asset_ids = params[:user_asset_ids]

      ActiveRecord::Base.transaction do
        user_assets = UserAsset.where(id: user_asset_ids)

        user_assets.each do |user_asset|
          unless user_asset.destroy
            error_message = user_asset.errors.full_messages.join("")
            redirect_to admin_user_assets_path, alert: "#{error_message} - #{t('activerecord.models.user_asset')} id: #{user_assets.id_user_asset}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_user_assets_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.user_asset")) }
        end
      end
    end

    def asset_item_types
      authorize :authorization, :read?

      if params[:query].present?
        query = params[:query].downcase
        asset_type = AssetType.find(query)
        asset_item_types = asset_type.asset_item_types
        render json: asset_item_types.pluck(:id, :name).map { |id, name| { id: id, name: name.capitalize } }
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

      start_time = Time.now

      if file.present?
        if !allowed_extension.include?(File.extname(file.original_filename))
          return redirect_back_or_to import_admin_user_assets_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        user_assets_attributes_headers = {
          id_user_asset: "User asset id",
          username: "Username",
          aztec_code: "Aztec code",
          email: "Email",
          site: "Site id",
          department: "Department id",
          floor: "Floor",
          location: "Location",
          description: "Description"
        }

        begin
          ActiveRecord::Base.transaction do
            sheet.parse(user_assets_attributes_headers).each do |row|
              site = Site.find_by_id_site(row[:site])
              department = Department.find_by_id_department(row[:department])

              if site.nil?
                redirect_back_or_to import_admin_user_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.site"), id: row[:site])
                raise ActiveRecord::Rollback
              end

              if row[:department].present?
                if department.nil?
                  redirect_back_or_to import_admin_user_assets_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.department"), id: row[:department])
                  raise ActiveRecord::Rollback
                end
              end

              data << {
                id_user_asset: row[:id_user_asset],
                username: row[:username],
                aztec_code: row[:aztec_code],
                email: row[:email],
                site_id: site.id,
                department_id: department&.id,
                location: row[:location],
                floor: row[:floor],
                description: row[:description]
              }

              if data.size >= batch_size
                UserAsset.insert_all!(data)
                data.clear
              end
            end

            UserAsset.insert_all!(data) unless data.empty?
          end

          respond_to do |format|
            logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
            format.html { redirect_to admin_user_assets_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.user_asset")) }
          end
        rescue Roo::HeaderRowNotFoundError => e
          redirect_to import_admin_user_assets_path, alert: t("custom.errors.invalid_import_template", errors: e)


        # Penanganan untuk duplikat data
        rescue ActiveRecord::RecordNotUnique => e
          logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
          duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
          duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
          humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
          redirect_back_or_to import_admin_user_assets_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

        # penangan error null violation
        rescue ActiveRecord::NotNullViolation => e
          logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
          error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
          error_row = data.find { |r| r[error_column.to_sym].nil? }

          error_message = "#{t('activerecord.attributes.user_asset.' + error_column)} " \
            "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
          redirect_back_or_to import_admin_user_assets_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

        # Penanganan umum untuk semua jenis error lainnya
        rescue => e
          logger.error "#{Current.request_id} - General error during import: #{e.message}"
          redirect_back_or_to import_admin_user_assets_path, alert: t("custom.errors.general_error")

        end

      else
        redirect_back_or_to import_admin_user_assets_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    def assets
      authorize :authorization, :read?
      @pundit_user = { account: current_account, function_access_code: FunctionAccessConstant::FA_ASSET }

      @q = @user_asset.assets.ransack(params[:q])
      @q.sorts = [ "tagging_id asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:project, :site, :asset_model, :asset_class, :delivery_order)
      @pagy, @assets = pagy(scope)

      if params[:q].present?
        respond_to do |format|
          format.turbo_stream do
            logger.debug "TURBO STREAM RENDER"
            render turbo_stream: turbo_stream.replace(
              "table_assets",
              partial: "admin/entries/user_assets/assets/turbo_table",
              locals: { assets: @assets, pagy: @pagy }
            )
          end
          format.html do
            logger.debug "fallback render"
            render partial: "admin/entries/user_assets/assets/turbo_table",
                   locals: { user_assets: @user_assets, pagy: @pagy }
          end
        end
      else
        # Permintaan awal: render view edit_location.html.erb
        logger.debug "first render"
        render :assets
      end
    end



    private

      def user_assets_params
        params.expect(user_asset: [ :username, :aztec_code, :email, :site_id, :department_id, :location, :floor, :description ])
      end

      def set_user_asset
        @user_asset = UserAsset.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ASS_REGISTER_USER_ASSET
      end

      def ensure_frame_response
        redirect_to admin_user_assets_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = admin_user_assets_path || root_path
      end
  end
end
