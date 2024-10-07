module Admin
  class SitesController < ApplicationAdminController
    before_action :set_site, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = Site.ransack(params[:q])
			scope = @q.result.includes(:site_stat, :site_group)
			@pagy, @sites = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @site = Site.new
    end

    def create
      authorize :authorization, :create?

      @site = Site.new(site_params)

      respond_to do |format|
        if @site.save
          format.html { redirect_to admin_sites_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.site"))}
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
				if @site.update(site_params)
					format.html { redirect_to admin_sites_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.site")) }
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

      site_ids = params[:site_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				sites = Site.where(id: site_ids)

				sites.each do |site|
					unless site.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = sites.map { |site| site.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_sites_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_sites_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.site")) }
					end
				end
			end
    end


    private

      def site_params
        params.expect(site: [ :name, :site_stat_id, :site_group_id, :description ])
      end

      def set_site
        @site = Site.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_LOC_SITE
      end
  end
end