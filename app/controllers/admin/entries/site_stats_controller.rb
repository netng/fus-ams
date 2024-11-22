module Admin::Entries
  class SiteStatsController < ApplicationAdminController
    before_action :set_site_stat, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :edit, :update, :new, :create ]
    before_action :set_previous_url

    def index
      authorize :authorization, :index?

      @q = SiteStat.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @site_stats = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @site_stat = SiteStat.new
    end

    def show
      authorize :authorization, :read?
    end

    def create
      authorize :authorization, :create?

      @site_stat = SiteStat.new(site_stat_params)

      respond_to do |format|
        if @site_stat.save
          format.html { redirect_to admin_site_stats_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.site_stat")) }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end


    def edit
      authorize :authorization, :update?

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@site_stat, partial: "admin/site_stats/form", locals: { site_stat: @site_stat })
        end
        format.html
      end
    end

    def update
      authorize :authorization, :update?

      respond_to do |format|
        if @site_stat.update(site_stat_params)
          format.html { redirect_to admin_site_stats_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.site_stat")) }
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

      site_stat_ids = params[:site_stat_ids]

      ActiveRecord::Base.transaction do
        site_stats = SiteStat.where(id: site_stat_ids)

        site_stats.each do |site_stat|
          unless site_stat.destroy
            error_message = site_stat.errors.full_messages.join("")
            redirect_to admin_site_stats_path, alert: "#{error_message} - #{t('activerecord.models.site_stat')} id: #{site_stat.id_site_stat}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_site_stats_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.site_stat")) }
        end
      end
    end

    def import
      authorize :authorization, :create?
    end


    private
      def site_stat_params
        params.expect(site_stat: [ :id_site_stat, :name, :description ])
      end

      def set_site_stat
        @site_stat = SiteStat.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_MST_SITE_STAT
      end

      def ensure_frame_response
        redirect_to admin_site_stats_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = admin_site_stats_path || root_path
      end
  end
end
