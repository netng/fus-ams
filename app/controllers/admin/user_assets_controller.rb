module Admin
  class UserAssetsController < ApplicationAdminController
    before_action :set_user_asset, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = UserAsset.ransack(params[:q])
      @q.sorts = ["id_user_asset asc"] if @q.sorts.empty?
			scope = @q.result.includes(:site, :department)
			@pagy, @user_assets = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @user_asset = UserAsset.new
      @user_asset.id_user_asset = "U-TEST-123"
    end

    def create
      authorize :authorization, :create?

      @user_asset = UserAsset.new(user_assets_params)

      respond_to do |format|
        if @user_asset.save
          format.html { redirect_to admin_user_assets_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.user_asset"))}
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
				if @user_assets.update(user_assets_params)
					format.html { redirect_to admin_user_assets_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.user_assets")) }
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
      allowed_extension = [".xlsx", ".csv"]
      file = params[:file]

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

        ActiveRecord::Base.transaction do
          begin
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

              user_asset = UserAsset.new(
                id_user_asset: row[:id_user_asset],
                username: row[:username],
                aztec_code: row[:aztec_code],
                email: row[:email],
                site: site,
                department: department,
                location: row[:location],
                floor: row[:floor],
                description: row[:description]
              )
  
              unless user_asset.save
                error_message = user_asset.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_user_assets_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_user_assets_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_user_assets_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.user_assets")) }
          end
        end
      else
        redirect_back_or_to import_admin_user_assets_path, alert: t("custom.flash.alerts.select_file")
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
  end
end