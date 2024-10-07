module Admin
  class SiteGroupsController < ApplicationAdminController
    before_action :set_site_group, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = SiteGroup.ransack(params[:q])
			scope = @q.result.includes(:project)
			@pagy, @site_groups = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @site_group = SiteGroup.new
    end

    def create
      authorize :authorization, :create?

      @site_group = SiteGroup.new(site_group_params)

      respond_to do |format|
        if @site_group.save
          format.html { redirect_to admin_site_groups_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.site_group"))}
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
				if @site_group.update(site_group_params)
					format.html { redirect_to admin_site_groups_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.site_group")) }
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

      site_group_ids = params[:site_group_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				site_groups = SiteGroup.where(id: site_group_ids)

				site_groups.each do |site_group|
					unless site_group.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = site_groups.map { |site_group| site_group.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_site_groups_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_site_groups_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.site_group")) }
					end
				end
			end
    end


    private

      def site_group_params
        params.expect(site_group: [ :name, :description, :project_id ])
      end

      def set_site_group
        @site_group = SiteGroup.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_SITE_GROUP
      end
  end
end