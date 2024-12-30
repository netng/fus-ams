module Admin::Master
  class ComponentTypesController < ApplicationAdminController
    before_action :set_component_type, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?

      @q = ComponentType.ransack(params[:q])
      scope = @q.result.order(name: :asc)
      @pagy, @component_types = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @component_type = ComponentType.new
    end

    def create
      authorize :authorization, :create?

      @component_type = ComponentType.new(component_type_params)

      respond_to do |format|
        if @component_type.save
          format.html { redirect_to admin_component_types_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.component_type")) }
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
        if @component_type.update(component_type_params)
          format.html { redirect_to admin_component_types_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.component_type")) }
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

      component_type_ids = params[:component_type_ids]

      ActiveRecord::Base.transaction do
        component_types = ComponentType.where(id: component_type_ids)

        component_types.each do |component_type|
          unless component_type.destroy
            error_message = component_type.errors.full_messages.join("")
            redirect_to admin_component_types_path, alert: "#{error_message} - #{t('activerecord.models.component_type')} id: #{component_type.id_component_type}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_component_types_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.component_type")) }
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
          return redirect_back_or_to import_admin_component_types_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        component_type_attributes_headers = {
          id_component_type: "Component type id",
          name: "Name",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(component_type_attributes_headers).each do |row|
              component_type = ComponentType.new(
                id_component_type: row[:id_component_type],
                name: row[:name],
                description: row[:description]
              )

              unless component_type.save
                error_message = component_type.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_component_types_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_component_types_path, alert: t("custom.errors.invalid_import_template", errors: e)

          end

          respond_to do |format|
            format.html { redirect_to admin_component_types_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.component_type")) }
          end
        end
      else
        redirect_back_or_to import_admin_component_types_path, alert: t("custom.flash.alerts.select_file")
      end
    end

    private

      def component_type_params
        params.expect(component_type: [ :id_component_type, :name, :description ])
      end

      def set_component_type
        @component_type = ComponentType.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_MST_COMPONENT_TYPE
      end

      def ensure_frame_response
        redirect_to admin_component_types_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = request.referer || admin_component_types_path || root_path
      end
  end
end
