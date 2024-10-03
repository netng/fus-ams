module Admin
  class BrandsController < ApplicationAdminController
    before_action :set_brand, only: [:edit, :update, :destroy]

    def index
      @q = Brand.ransack(params[:q])
			scope = @q.result
			@pagy, @brands = pagy(scope)
    end

    def new
      @brand = Brand.new
    end

    def create
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
    end

    def update
      respond_to do |format|
				if @brand.update(brand_params)
					format.html { redirect_to admin_brands_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.brand")) }
				else
					format.html { render :new, status: :unprocessable_entity }
				end
			end
    end

    def destroy
    end

    def destroy_many
      brand_ids = params[:brand_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				brands = Brand.where(id: brand_ids)

				brands.each do |brand|
					unless brand.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = brands.map { |brand| brand.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_brands_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_brands_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.brand")) }
					end
				end
			end
    end

    private
      def brand_params
        params.require(:brand).permit(:name, :description)
      end

      def set_brand
        @brand = Brand.find(params[:id])
      end

  end
end
