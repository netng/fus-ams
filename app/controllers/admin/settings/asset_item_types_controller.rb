module Admin::Settings
  class AssetItemTypesController < ApplicationAdminController
    before_action :set_asset_item_type, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?

      @q = AssetItemType.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:asset_type)
      @pagy, @asset_item_types = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @asset_item_type = AssetItemType.new
    end

    def create
      authorize :authorization, :create?

      @asset_item_type = AssetItemType.new(asset_item_type_params)

      respond_to do |format|
        if @asset_item_type.save
          format.html { redirect_to admin_asset_item_types_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.asset_item_type")) }
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
        if @asset_item_type.update(asset_item_type_params)
          format.html { redirect_to admin_asset_item_types_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset_item_type")) }
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

      asset_item_type_ids = params[:asset_item_type_ids]

      ActiveRecord::Base.transaction do
        asset_item_types = AssetItemType.where(id: asset_item_type_ids)

        asset_item_types.each do |asset_item_type|
          unless asset_item_type.destroy
            error_message = asset_item_type.errors.full_messages.join("")
            redirect_to admin_asset_item_types_path, alert: "#{error_message} - #{t('activerecord.models.asset_item_type')} id: #{asset_item_type.id_asset_item_type}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_asset_item_types_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.asset_item_type")) }
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
          return redirect_back_or_to import_admin_asset_item_types_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        asset_item_type_attributes_headers = {
          id_asset_item_type: "Asset item type id",
          name: "Name",
          asset_type: "Asset type id",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(asset_item_type_attributes_headers).each do |row|
              asset_type = AssetType.find_by_id_asset_type(row[:asset_type])

              if asset_type.nil?
                redirect_back_or_to import_admin_asset_item_types_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_type"), id: row[:asset_type])
                raise ActiveRecord::Rollback
              end

              asset_item_type = AssetItemType.new(
                id_asset_item_type: row[:id_asset_item_type],
                name: row[:name],
                asset_type: asset_type,
                description: row[:description]
              )

              unless asset_item_type.save
                error_message = asset_item_type.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_asset_item_types_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_asset_item_types_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_asset_item_types_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset_item_type")) }
          end
        end
      else
        redirect_back_or_to import_admin_asset_item_types_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def asset_item_type_params
        params.expect(asset_item_type: [ :id_asset_item_type, :name, :description, :asset_type_id ])
      end

      def set_asset_item_type
        @asset_item_type = AssetItemType.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_SET_ASSET_ITEM_TYPE
      end

      def ensure_frame_response
        redirect_to admin_asset_item_types_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = request.referer || admin_asset_item_types_path || root_path
      end
  end
end
