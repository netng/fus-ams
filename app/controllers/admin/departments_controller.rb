module Admin
  class DepartmentsController < ApplicationAdminController
    before_action :set_department, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = Department.ransack(params[:q])
			scope = @q.result
			@pagy, @departments = pagy(scope)
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
          format.html { redirect_to admin_departments_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.department"))}
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
					format.html { render :new, status: :unprocessable_entity }
				end
			end
    end

    def destroy
      authorize :authorization, :destroy?

    end

    def destroy_many
      authorize :authorization, :destroy?

      department_ids = params[:department_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				departments = Department.where(id: department_ids)

				departments.each do |department|
					unless department.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = departments.map { |department| department.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_departments_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_departments_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.department")) }
					end
				end
			end
    end

    private
      def department_params
        params.expect(department: [ :name, :floor, :description ])
      end

      def set_department
        @department = Department.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_DEPARTMENT
      end

  end
end
