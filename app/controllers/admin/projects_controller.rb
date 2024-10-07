module Admin
  class ProjectsController < ApplicationAdminController
    before_action :set_project, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = Project.ransack(params[:q])
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
					format.html { render :new, status: :unprocessable_entity }
				end
			end
    end

    def destroy
      authorize :authorization, :destroy?

    end

    def destroy_many
      authorize :authorization, :destroy?

      project_ids = params[:project_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				projects = Project.where(id: project_ids)

				projects.each do |project|
					unless project.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = projects.map { |project| project.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_projects_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_projects_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.project")) }
					end
				end
			end
    end


    private

      def project_params
        params.expect(project: [ :name, :description ])
      end

      def set_project
        @project = Project.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_MST_PROJECT
      end
  end
end