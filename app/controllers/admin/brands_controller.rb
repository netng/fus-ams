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
