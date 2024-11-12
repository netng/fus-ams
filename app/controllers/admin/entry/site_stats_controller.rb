module Admin::Entry
  class SiteStatsController < ApplicationAdminController
    before_action :set_site_stat, only: [ :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :edit, :update, :new, :create ]
    def index
      authorize :authorization, :index?

      @q = SiteStat.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @site_stats = pagy(scope)
    end

    def new
      authorize :authorization, :create?
      @previous_url = admin_site_stats_path || root_path

      @site_stat = SiteStat.new
    end

    def create
      authorize :authorization, :create?
      @previous_url = admin_site_stats_path || root_path


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
      @previous_url = admin_site_stats_path || root_path


      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@site_stat, partial: "admin/site_stats/form", locals: { site_stat: @site_stat })
        end
        format.html
      end
    end

    def update
      authorize :authorization, :update?
      @previous_url = admin_site_stats_path || root_path


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

    def process_import
      authorize :authorization, :create?
      allowed_extension = [ ".xlsx", ".csv" ]
      file = params[:file]

      if file.present?
        if !allowed_extension.include?(File.extname(file.original_filename))
          return redirect_back_or_to import_admin_site_stats_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        # buka file menggunakan roo
        xlsx = Roo::Spreadsheet.open(file.path)

        # ambil sheet pertama
        sheet = xlsx.sheet(0)

        site_stat_attributes_headers = {
          id_site_stat: "Site stat id",
          name: "Name",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(site_stat_attributes_headers).each do |row|
              site_stat = SiteStat.new(
                id_site_stat: row[:id_site_stat],
                name: row[:name],
                description: row[:description]
              )

              unless site_stat.save
                error_message = site_stat.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_site_stats_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_site_stats_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_site_stats_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.site_stat")) }
          end
        end
      else
        redirect_back_or_to import_admin_site_stats_path, alert: t("custom.flash.alerts.select_file")
      end
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
  end
end
