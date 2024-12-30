module Admin::Master
  class SoftwaresController < ApplicationAdminController
    before_action :set_software, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :new, :create, :edit, :update ]
    before_action :set_previous_url


    def index
      authorize :authorization, :index?

      @q = Software.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @softwares = pagy(scope)
    end

    def show
      authorize :authorization, :read?
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
          format.html { redirect_to admin_softwares_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.software")) }
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
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize :authorization, :destroy?
    end

    def destroy_many
      authorize :authorization, :destroy?

      software_ids = params[:software_ids]

      ActiveRecord::Base.transaction do
        softwares = Software.where(id: software_ids)

        softwares.each do |software|
          unless software.destroy
            error_message = software.errors.full_messages.join("")
            redirect_to admin_softwares_path, alert: "#{error_message} - #{t('activerecord.models.software')} id: #{software.id_software}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_softwares_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.software")) }
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
          return redirect_back_or_to import_admin_softwares_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        xlsx = Roo::Spreadsheet.open(file.path)

        sheet = xlsx.sheet(0)

        software_attributes_headers = {
          id_software: "Software id",
          name: "Name",
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(software_attributes_headers).each do |row|
              software = Software.new(
                id_software: row[:id_software],
                name: row[:name],
                description: row[:description]
              )

              unless software.save
                error_message = software.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_softwares_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_softwares_path, alert: t("custom.errors.invalid_import_template", errors: e)

          end

          respond_to do |format|
            format.html { redirect_to admin_softwares_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.software")) }
          end
        end
      else
        redirect_back_or_to import_admin_softwares_path, alert: t("custom.flash.alerts.select_file")
      end
    end

    private

      def software_params
        params.expect(software: [ :id_software, :name, :description ])
      end

      def set_software
        @software = Software.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_MST_SOFTWARE
      end

      def ensure_frame_response
        redirect_to admin_softwares_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = request.referer || admin_softwares_path || root_path
      end
  end
end
