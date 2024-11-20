module Admin::Entries
  class ComponentsController < ApplicationAdminController
    before_action :set_component, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?

      @q = Component.ransack(params[:q])
      @q.sorts = [ "component_type_name asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:component_type)
      @pagy, @components = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @component = Component.new
    end

    def create
      authorize :authorization, :create?

      @component = Component.new(component_params)

      respond_to do |format|
        if @component.save
          format.html { redirect_to admin_components_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.component")) }
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
        if @component.update(component_params)
          format.html { redirect_to admin_components_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.component")) }
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

      component_ids = params[:component_ids]

      ActiveRecord::Base.transaction do
        components = Component.where(id: component_ids)

        components.each do |component|
          unless component.destroy
            error_message = component.errors.full_messages.join("")
            redirect_to admin_components_path, alert: "#{error_message} - #{t('activerecord.models.component')} id: #{component.id_component}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_components_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.component")) }
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
          return redirect_back_or_to import_admin_components_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        component_attributes_headers = {
          id_component: "Component id",
          name: "Name",
          component_type: "Component type id",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(component_attributes_headers).each do |row|
              component_type = ComponentType.find_by_id_component_type(row[:component_type])

              if component_type.nil?
                redirect_back_or_to import_admin_components_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.component_type"), id: row[:component_type])
                raise ActiveRecord::Rollback
              end

              component = Component.new(
                id_component: row[:id_component],
                name: row[:name],
                component_type: component_type,
                description: row[:description]
              )

              unless component.save
                error_message = component.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_components_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_components_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_components_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.component")) }
          end
        end
      else
        redirect_back_or_to import_admin_components_path, alert: t("custom.flash.alerts.select_file")
      end
    end

    private

      def component_params
        params.expect(component: [ :id_component, :name, :description, :component_type_id ])
      end

      def set_component
        @component = Component.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ASS_COM_COMPONENT
      end

      def ensure_frame_response
        redirect_to admin_components_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = admin_components_path || root_path
      end
  end
end
