module Admin::Entries
  class SiteDefaultsController < ApplicationAdminController
    before_action :set_site_default, only: [ :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :new, :update, :edit, :create ]

    def index
      authorize :authorization, :index?

      @q = SiteDefault.ransack(params[:q])
      @q.sorts = [ "site_name asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:site)
      @pagy, @site_defaults = pagy(scope)
      @site_site_defaults = SiteDefault.joins(:site).select(sites: [ :name, :id ])
    end

    def new
      authorize :authorization, :create?

      @site_default = SiteDefault.new
      @previous_url = admin_site_defaults_path || root_path
    end

    def create
      authorize :authorization, :create?

      @site_default = SiteDefault.new(site_default_params)
      @previous_url = admin_site_defaults_path || root_path

      respond_to do |format|
        ActiveRecord::Base.transaction do
          if @site_default.save
            user_asset = UserAsset.find_by_id_user_asset(@site_default.id_user_site_default)
            unless user_asset
              UserAsset.new(id_user_asset: @site_default.id_user_site_default, site: @site_default.site).save
            end
            format.html { redirect_to admin_site_defaults_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.site_default")) }
          end
        end
          format.html { render :new, status: :unprocessable_entity }
      end
    end

    def edit
      authorize :authorization, :update?
      @previous_url = admin_site_defaults_path || root_path
    end

    def update
      authorize :authorization, :update?
      @previous_url = admin_site_defaults_path || root_path

      respond_to do |format|
        if @site_default.update(site_default_params)
          format.html { redirect_to admin_site_defaults_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.site_default")) }
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

      site_default_ids = params[:site_default_ids]

      ActiveRecord::Base.transaction do
        site_defaults = SiteDefault.where(id: site_default_ids)

        site_defaults.each do |site_default|
          unless site_default.destroy
            error_message = site_default.errors.full_messages.join("")
            redirect_to admin_site_defaults_path, alert: "#{error_message} - #{t('activerecord.models.site_default')} id: #{site_default.id_user_site_default}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_site_defaults_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.site_default")) }
        end
      end
    end

    # def import
    #   authorize :authorization, :create?
    # end

    # def process_import
    #   authorize :authorization, :create?
    #   allowed_extension = [".xlsx", ".csv"]
    #   file = params[:file]

    #   if file.present?
    #     if !allowed_extension.include?(File.extname(file.original_filename))
    #       return redirect_back_or_to import_admin_site_defaults_path, alert: t("custom.errors.invalid_allowed_extension")
    #     end

    #     # buka file menggunakan roo
    #     xlsx = Roo::Spreadsheet.open(file.path)

    #     # ambil sheet pertama
    #     sheet = xlsx.sheet(0)

    #     site_default_attributes_headers = {
    #       id_user_site_default: "Site Default id",
    #       name: "Name",
    #       project: "Project id",
    #       description: "Description"
    #     }

    #     ActiveRecord::Base.transaction do
    #       begin
    #         sheet.parse(site_default_attributes_headers).each do |row|

    #           project = Project.find_by_id_project(row[:project])

    #           if project.nil?
    #             redirect_back_or_to import_admin_site_defaults_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.project"), id: row[:project])
    #             raise ActiveRecord::Rollback
    #           end

    #           site_default = SiteDefault.new(
    #             id_user_site_default: row[:id_user_site_default],
    #             name: row[:name],
    #             project: project,
    #             description: row[:description]
    #           )

    #           unless site_default.save
    #             error_message = site_default.errors.details.map do |field, error_details|
    #               error_details.map do |error|
    #                 "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
    #               end
    #             end.flatten.join("")

    #             redirect_to import_admin_site_defaults_path, alert: error_message
    #             raise ActiveRecord::Rollback
    #           end
    #         end
    #       rescue Roo::HeaderRowNotFoundError => e
    #         return redirect_to import_admin_site_defaults_path, alert: t("custom.errors.invalid_import_template", errors: e)
    #       end

    #       respond_to do |format|
    #         format.html { redirect_to admin_site_defaults_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.site_default")) }
    #       end
    #     end
    #   else
    #     redirect_back_or_to import_admin_site_defaults_path, alert: t("custom.flash.alerts.select_file")
    #   end
    # end


    private

      def site_default_params
        params.expect(site_default: [ :id_user_site_default, :site_id, :description ])
      end

      def set_site_default
        @site_default = SiteDefault.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_LOC_SITE_DEFAULT
      end

      def ensure_frame_response
        redirect_to admin_site_defaults_path unless turbo_frame_request?
      end
  end
end
