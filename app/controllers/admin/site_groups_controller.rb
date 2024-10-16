module Admin
  class SiteGroupsController < ApplicationAdminController
    before_action :set_site_group, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = SiteGroup.ransack(params[:q])
			scope = @q.result.includes(:project).order(name: :asc)
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
					format.html { render :edit, status: :unprocessable_entity }
				end
			end
    end

    def destroy
      authorize :authorization, :destroy?

    end

    def destroy_many
      authorize :authorization, :destroy?

      site_group_ids = params[:site_group_ids]

			ActiveRecord::Base.transaction do
				site_groups = SiteGroup.where(id: site_group_ids)

				site_groups.each do |site_group|
					unless site_group.destroy
						error_message = site_group.errors.full_messages.join("")
            redirect_to admin_site_groups_path, alert: "#{error_message} - #{t('activerecord.models.site_group')} id: #{site_group.id_site_group}"
            raise ActiveRecord::Rollback
					end
				end
				
				respond_to do |format|
					format.html { redirect_to admin_site_groups_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.site_group")) }
				end
			end
    end

    def import
      authorize :authorization, :create?
    end

    def process_import
      authorize :authorization, :create?
      allowed_extension = [".xlsx", ".csv"]
      file = params[:file]

      if file.present?
        if !allowed_extension.include?(File.extname(file.original_filename))
          return redirect_back_or_to import_admin_site_groups_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        # buka file menggunakan roo
        xlsx = Roo::Spreadsheet.open(file.path)

        # ambil sheet pertama
        sheet = xlsx.sheet(0)

        site_group_attributes_headers = {
          id_site_group: "Site group id",
          name: "Name",
          project: "Project id",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(site_group_attributes_headers).each do |row|

              project = Project.find_by_id_project(row[:project])

              if project.nil?
                redirect_back_or_to import_admin_projects_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.project"), id: row[:project])
                raise ActiveRecord::Rollback
              end

              site_group = SiteGroup.new(
                id_site_group: row[:id_site_group],
                name: row[:name],
                project: Project.find_by_id_project!(row[:project]),
                description: row[:description]
              )
  
              unless site_group.save
                error_message = site_group.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_site_groups_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_site_groups_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_site_groups_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.site_group")) }
          end
        end
      else
        redirect_back_or_to import_admin_site_groups_path, alert: t("custom.flash.alerts.select_file")
      end
    end


    private

      def site_group_params
        params.expect(site_group: [ :id_site_group, :name, :description, :project_id ])
      end

      def set_site_group
        @site_group = SiteGroup.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_LOC_SITE_GROUP
      end
  end
end