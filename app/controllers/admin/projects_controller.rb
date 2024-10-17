module Admin
  class ProjectsController < ApplicationAdminController
    before_action :set_project, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = Project.ransack(params[:q])
      @q.sorts = ["name asc"] if @q.sorts.empty?
			scope = @q.result
			@pagy, @projects = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @project = Project.new
    end

    def create
      authorize :authorization, :create?

      @project = Project.new(project_params)

      respond_to do |format|
        if @project.save
          format.html { redirect_to admin_projects_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.project"))}
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
				if @project.update(project_params)
					format.html { redirect_to admin_projects_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.project")) }
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

      project_ids = params[:project_ids]

			ActiveRecord::Base.transaction do
				projects = Project.where(id: project_ids)

				projects.each do |project|
					unless project.destroy
						error_message = project.errors.full_messages.join("")
            redirect_to admin_projects_path, alert: "#{error_message} - #{t('activerecord.models.project')} id: #{project.id_project}"
            raise ActiveRecord::Rollback
					end
				end
				
				respond_to do |format|
					format.html { redirect_to admin_projects_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.project")) }
				end
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
          return redirect_back_or_to import_admin_projects_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        # buka file menggunakan roo
        xlsx = Roo::Spreadsheet.open(file.path)

        # ambil sheet pertama
        sheet = xlsx.sheet(0)

        project_attributes_headers = {
          id_project: "Project id",
          name: "Name",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(project_attributes_headers).each do |row|
  
              project = Project.new(
                id_project: row[:id_project],
                name: row[:name],
                description: row[:description]
              )
  
              unless project.save
                error_message = project.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_projects_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_projects_path, alert: t("custom.errors.invalid_import_template", errors: e)

          end

          respond_to do |format|
            format.html { redirect_to admin_projects_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.project")) }
          end
        end
      else
        redirect_back_or_to import_admin_projects_path, alert: t("custom.flash.alerts.select_file")
      end
    end

    private

      def project_params
        params.expect(project: [ :id_project, :name, :description ])
      end

      def set_project
        @project = Project.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_MST_PROJECT
      end
  end
end