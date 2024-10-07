module Admin
  class SoftwaresController < ApplicationAdminController
    before_action :set_software, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = Software.ransack(params[:q])
			scope = @q.result
			@pagy, @softwares = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @software = Software.new
    end

    def create
      authorize :authorization, :create?

      @software = Software.new(software_params)

      respond_to do |format|
        if @software.save
          format.html { redirect_to admin_softwares_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.software"))}
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
				if @software.update(software_params)
					format.html { redirect_to admin_softwares_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.software")) }
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

      software_ids = params[:software_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				softwares = Software.where(id: software_ids)

				softwares.each do |software|
					unless software.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = softwares.map { |software| software.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_softwares_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_softwares_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.software")) }
					end
				end
			end
    end


    private

      def software_params
        params.expect(software: [ :name, :description ])
      end

      def set_software
        @software = Software.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_ASS_COM_SOFTWARE
      end
  end
end