module Admin
  class SiteStatsController < ApplicationAdminController
    before_action :set_site_stat, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = SiteStat.ransack(params[:q])
			scope = @q.result
			@pagy, @site_stats = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @site_stat = SiteStat.new
    end

    def create
      authorize :authorization, :create?

      @site_stat = SiteStat.new(site_stat_params)

      respond_to do |format|
        if @site_stat.save
          format.html { redirect_to admin_site_stats_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.site_stat"))}
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
				if @site_stat.update(site_stat_params)
					format.html { redirect_to admin_site_stats_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.site_stat")) }
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

      site_stat_ids = params[:site_stat_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				site_stats = SiteStat.where(id: site_stat_ids)

				site_stats.each do |site_stat|
					unless site_stat.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = site_stats.map { |site_stat| site_stat.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_site_stats_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_site_stats_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.site_stat")) }
					end
				end
			end
    end

    private
      def site_stat_params
        params.expect(site_stat: [ :name, :description ])
      end

      def set_site_stat
        @site_stat = SiteStat.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_MST_SITE_STAT
      end

  end
end
