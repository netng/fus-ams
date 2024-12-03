module Admin::Entries
  class AssetTypesController < ApplicationAdminController
    before_action :set_asset_type, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?

      @q = AssetType.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @asset_types = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @asset_type = AssetType.new
    end

    def create
      authorize :authorization, :create?

      @asset_type = AssetType.new(asset_type_params)

      respond_to do |format|
        if @asset_type.save
          format.html { redirect_to admin_asset_types_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.asset_type")) }
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
        if @asset_type.update(asset_type_params)
          format.html { redirect_to admin_asset_types_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset_type")) }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize :authorization, :destroy?
    end

    def destroy_many
      authorize :authorization, :destroy?

      asset_type_ids = params[:asset_type_ids]

      ActiveRecord::Base.transaction do
        asset_types = AssetType.where(id: asset_type_ids)

        asset_types.each do |asset_type|
          unless asset_type.destroy
            error_message = asset_type.errors.full_messages.join("")
            redirect_to admin_asset_types_path, alert: "#{error_message} - #{t('activerecord.models.asset_type')} id: #{asset_type.id_asset_type}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_asset_types_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.asset_type")) }
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

      if file.present?
        if !allowed_extension.include?(File.extname(file.original_filename))
          return redirect_back_or_to import_admin_asset_types_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        asset_type_attributes_headers = {
          id_asset_type: "Asset type id",
          name: "Name",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(asset_type_attributes_headers).each do |row|
              asset_type = AssetType.new(
                id_asset_type: row[:id_asset_type],
                name: row[:name],
                description: row[:description]
              )

              unless asset_type.save
                error_message = asset_type.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_asset_types_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_asset_types_path, alert: t("custom.errors.invalid_import_template", errors: e)

          end

          respond_to do |format|
            format.html { redirect_to admin_asset_types_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset_type")) }
          end
        end
      else
        redirect_back_or_to import_admin_asset_types_path, alert: t("custom.flash.alerts.select_file")
      end
    end

    private

      def asset_type_params
        params.expect(asset_type: [ :id_asset_type, :name, :description ])
      end

      def set_asset_type
        @asset_type = AssetType.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ASS_COM_ASSET_TYPE
      end

      def ensure_frame_response
        redirect_to admin_asset_types_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = request.referer || admin_asset_types_path || root_path
      end
  end
end
