module Admin
  class BrandsController < ApplicationAdminController
    before_action :set_brand, only: [:edit, :update, :destroy]
		before_action :set_function_access_code


    def index
      authorize :authorization, :index?

      @q = Brand.ransack(params[:q])
      @q.sorts = ["name asc"] if @q.sorts.empty?
			scope = @q.result
			@pagy, @brands = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @brand = Brand.new
    end

    def create
      authorize :authorization, :create?

      @brand = Brand.new(brand_params)

      respond_to do |format|
        if @brand.save
          format.html { redirect_to admin_brands_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.brand"))}
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
				if @brand.update(brand_params)
					format.html { redirect_to admin_brands_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.brand")) }
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

      brand_ids = params[:brand_ids]

			ActiveRecord::Base.transaction do
				brands = Brand.where(id: brand_ids)

				brands.each do |brand|
					unless brand.destroy
            redirect_to admin_brands_path, alert: "#{brand.errors.full_messages.join("")} - #{t('activerecord.models.brand')} id: #{brand.id_brand}"
            raise ActiveRecord::Rollback
					end
				end
				
				respond_to do |format|
					format.html { redirect_to admin_brands_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.brand")) }
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
          return redirect_back_or_to import_admin_brands_path, alert: t("custom.errors.invalid_allowed_extension")
        end

        # buka file menggunakan roo
        xlsx = Roo::Spreadsheet.open(file.path)

        # ambil sheet pertama
        sheet = xlsx.sheet(0)

        brand_attributes_headers = {
          id_brand: 'Brand id',
          name: 'Name',
          description: "Description"
        }

        ActiveRecord::Base.transaction do
          begin
            sheet.parse(brand_attributes_headers).each do |row|
  
              brand = Brand.new(
                id_brand: row[:id_brand],
                name: row[:name],
                description: row[:description]
              )
  
              unless brand.save
                error_message = brand.errors.details.map do |field, error_details|
                  error_details.map do |error|
                    "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                  end
                end.flatten.join("")

                redirect_to import_admin_brands_path, alert: error_message
                raise ActiveRecord::Rollback
              end
            end
          rescue Roo::HeaderRowNotFoundError => e
            return redirect_to import_admin_brands_path, alert: t("custom.errors.invalid_import_template", errors: e)
          end

          respond_to do |format|
            format.html { redirect_to admin_brands_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.brand")) }
          end
        end
      else
        redirect_back_or_to import_admin_brands_path, alert: t("custom.flash.alerts.select_file")
      end
    end

    private
      def brand_params
        params.require(:brand).permit(:id_brand, :name, :description)
      end

      def set_brand
        @brand = Brand.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_MST_BRAND
      end

  end
end
