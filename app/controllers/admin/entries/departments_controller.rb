module Admin::Entries
  class DepartmentsController < ApplicationAdminController
    before_action :set_department, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?

      @q = Department.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @departments = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @department = Department.new
    end

    def create
      authorize :authorization, :create?

      @department = Department.new(department_params)

      respond_to do |format|
        if @department.save
          format.html { redirect_to admin_departments_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.department")) }
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
        if @department.update(department_params)
          format.html { redirect_to admin_departments_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.department")) }
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

      department_ids = params[:department_ids]

      ActiveRecord::Base.transaction do
        departments = Department.where(id: department_ids)

        departments.each do |department|
          unless department.destroy
            error_message = department.errors.full_messages.join("")
            redirect_to admin_departments_path, alert: "#{error_message} - #{t('activerecord.models.department')} id: #{department.id_department}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_departments_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.department")) }
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
          return redirect_back_or_to import_admin_departments_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        # buka file menggunakan roo
        xlsx = Roo::Spreadsheet.open(file.path)

        # ambil sheet pertama
        sheet = xlsx.sheet(0)

        department_attributes_headers = {
          id_department: "Department id",
          name: "Name",
          floor: "Floor",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(department_attributes_headers).each do |row|
              department = Department.new(
                id_department: row[:id_department],
                name: row[:name],
                floor: row[:floor],
                description: row[:description]
              )

              unless department.save
                error_message = department.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_departments_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_departments_path, alert: t("custom.errors.invalid_import_template", errors: e)

          end

          respond_to do |format|
            format.html { redirect_to admin_departments_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.department")) }
          end
        end
      else
        redirect_back_or_to import_admin_departments_path, alert: t("custom.flash.alerts.select_file")
      end
    end

    private
      def department_params
        params.expect(department: [ :id_department, :name, :floor, :description ])
      end

      def set_department
        @department = Department.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_LOC_DEPARTMENT
      end

      def ensure_frame_response
        redirect_to admin_departments_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = admin_departments_path || root_path
      end
  end
end
