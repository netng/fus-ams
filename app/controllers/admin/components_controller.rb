module Admin
  class ComponentsController < ApplicationAdminController
    before_action :set_component, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = Component.ransack(params[:q])
			scope = @q.result.includes(:component_type)
			@pagy, @components = pagy(scope)
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
          format.html { redirect_to admin_components_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.component"))}
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
					format.html { render :new, status: :unprocessable_entity }
				end
			end
    end

    def destroy
      authorize :authorization, :destroy?

    end

    def destroy_many
      authorize :authorization, :destroy?

      component_ids = params[:component_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				components = Component.where(id: component_ids)

				components.each do |component|
					unless component.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = components.map { |component| component.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_components_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_components_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.component")) }
					end
				end
			end
    end


    private

      def component_params
        params.expect(component: [ :name, :description, :component_type_id ])
      end

      def set_component
        @component = Component.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_ASS_COM_COMPONENT
      end
  end
end