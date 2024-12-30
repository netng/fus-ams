module Admin::Settings
  class SitesController < ApplicationAdminController
    before_action :set_site, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update ]
    before_action :set_previous_url
    before_action :set_parent_site, only: [ :new, :create, :edit, :update ]

    def index
      authorize :authorization, :index?

      @q = Site.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:site_stat, :site_group, :parent_site)
      @pagy, @sites = pagy(scope)
    end

    def show
      authorize :authorization, :read?
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
          format.html { redirect_to admin_sites_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.site")) }
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
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(@site, partial: "admin/entries/sites/site", locals: { site: @site })
          end
          format.html { redirect_to admin_sites_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.site")) }
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

      site_ids = params[:site_ids]

      ActiveRecord::Base.transaction do
        sites = Site.where(id: site_ids)

        sites.each do |site|
          unless site.destroy
            error_message = site.errors.full_messages.join("")
            redirect_to admin_sites_path, alert: "#{error_message} - #{t('activerecord.models.site')} id: #{site.id_site}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_sites_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.site")) }
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
          return redirect_back_or_to import_admin_sites_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        site_attributes_headers = {
          id_site: "Site id",
          name: "Name",
          site_stat: "Site status id",
          site_group: "Site group id",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(site_attributes_headers).each do |row|
              site_stat = SiteStat.find_by_id_site_stat(row[:site_stat])
              site_group = SiteGroup.find_by_id_site_group(row[:site_group])

              if site_stat.nil?
                redirect_back_or_to import_admin_site_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.site_stat"), id: row[:site_stat])
                raise ActiveRecord::Rollback
              end

              if site_group.nil?
                redirect_back_or_to import_admin_site_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.site_group"), id: row[:site_group])
                raise ActiveRecord::Rollback
              end

              site = Site.new(
                id_site: row[:id_site],
                name: row[:name],
                site_stat: site_stat,
                site_group: site_group,
                description: row[:description]
              )

              unless site.save
                error_message = site.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_sites_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_sites_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_sites_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.site")) }
          end
        end
      else
        redirect_back_or_to import_admin_sites_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def site_params
        params.expect(site: [ :id_site, :name, :site_stat_id, :site_id, :site_group_id, :parent_site_id, :description ])
      end

      def set_site
        @site = Site.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_SET_SITE
      end

      def ensure_frame_response
        redirect_to admin_sites_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = request.referer || admin_sites_path || root_path
        logger.debug "============ URL ===============: #{request.fullpath}"
        logger.debug "URL REFERRER: #{request.referer}"
      end

      def set_parent_site
        @parent_sites = Site.all.reject { |site| site.parent_site != nil }
          .pluck(:name, :id)
          .map { |name, id| [ name, id ] }
      end
  end
end
