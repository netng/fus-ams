module Admin::Entries
  class AssetModelsController < ApplicationAdminController
    before_action :set_asset_model, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?

      @q = AssetModel.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:brand, :asset_type, :asset_item_type)
      @pagy, @asset_models = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @asset_model = AssetModel.new
      @asset_item_types = @asset_model.asset_type&.asset_item_types&.pluck(:name, :id)&.map { |name, id| [ name.capitalize, id ] } || []
    end

    def create
      authorize :authorization, :create?

      @asset_model = AssetModel.new(asset_model_params)
      @asset_item_types = @asset_model.asset_type&.asset_item_types&.pluck(:name, :id)&.map { |name, id| [ name.capitalize, id ] } || []


      respond_to do |format|
        if @asset_model.save
          format.html { redirect_to admin_asset_models_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.asset_model")) }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize :authorization, :update?
      @asset_item_types = @asset_model.asset_type&.asset_item_types&.pluck(:name, :id)&.map { |name, id| [ name.capitalize, id ] } || []
    end

    def update
      authorize :authorization, :update?
      @asset_item_types = @asset_model.asset_type&.asset_item_types&.pluck(:name, :id)&.map { |name, id| [ name.capitalize, id ] } || []

      respond_to do |format|
        if @asset_model.update(asset_model_params)
          format.html { redirect_to admin_asset_models_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset_model")) }
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

      asset_model_ids = params[:asset_model_ids]

      ActiveRecord::Base.transaction do
        asset_models = AssetModel.where(id: asset_model_ids)

        asset_models.each do |asset_model|
          unless asset_model.destroy
            error_message = asset_model.errors.full_messages.join("")
            redirect_to admin_asset_models_path, alert: "#{error_message} - #{t('activerecord.models.asset_model')} id: #{asset_model.id_asset_model}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_asset_models_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.asset_model")) }
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

      if file.present?
        if !allowed_extension.include?(File.extname(file.original_filename))
          return redirect_back_or_to import_admin_asset_models_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        asset_model_attributes_headers = {
          id_asset_model: "Asset model id",
          name: "Name",
          brand: "Brand id",
          asset_type: "Asset type id",
          asset_item_type: "Asset item type id",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(asset_model_attributes_headers).each do |row|
              brand = Brand.find_by_id_brand(row[:brand])
              asset_type = AssetType.find_by_id_asset_type(row[:asset_type])
              asset_item_type = AssetItemType.find_by_id_asset_item_type(row[:asset_item_type])

              if brand.nil?
                redirect_back_or_to import_admin_asset_models_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.brand"), id: row[:brand])
                raise ActiveRecord::Rollback
              end

              if asset_type.nil?
                redirect_back_or_to import_admin_asset_models_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_type"), id: row[:asset_type])
                raise ActiveRecord::Rollback
              end

              if asset_item_type.nil?
                redirect_back_or_to import_admin_asset_models_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_item_type"), id: row[:asset_item_type])
                raise ActiveRecord::Rollback
              end

              asset_model = AssetModel.new(
                id_asset_model: row[:id_asset_model],
                name: row[:name],
                brand: brand,
                asset_type: asset_type,
                asset_item_type: asset_item_type,
                description: row[:description]
              )

              unless asset_model.save
                error_message = asset_model.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_asset_models_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_asset_models_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_asset_models_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset_model")) }
          end
        end
      else
        redirect_back_or_to import_admin_asset_models_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def asset_model_params
        params.expect(asset_model: [ :id_asset_model, :name, :description, :brand_id, :asset_type_id, :asset_item_type_id ])
      end

      def set_asset_model
        @asset_model = AssetModel.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ASS_COM_ASSET_MODEL
      end

      def ensure_frame_response
        redirect_to admin_asset_models_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = request.referer || admin_asset_models_path || root_path
      end
  end
end
