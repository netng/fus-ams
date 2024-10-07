module Admin
  class ComponentTypesController < ApplicationAdminController
    before_action :set_component_type, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = ComponentType.ransack(params[:q])
			scope = @q.result
			@pagy, @component_types = pagy(scope)
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
          format.html { redirect_to admin_component_types_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.component_type"))}
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
					format.html { render :new, status: :unprocessable_entity }
				end
			end
    end

    def destroy
      authorize :authorization, :destroy?

    end

    def destroy_many
      authorize :authorization, :destroy?

      component_type_ids = params[:component_type_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				component_types = ComponentType.where(id: component_type_ids)

				component_types.each do |component_type|
					unless component_type.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = component_types.map { |component_type| component_type.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_component_types_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_component_types_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.component_type")) }
					end
				end
			end
    end


    private

      def component_type_params
        params.expect(component_type: [ :name, :description ])
      end

      def set_component_type
        @component_type = ComponentType.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_ASS_COM_COMPONENT_TYPE
      end
  end
end