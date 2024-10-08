module Admin
  class AssetTypesController < ApplicationAdminController
    before_action :set_asset_type, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = AssetType.ransack(params[:q])
			scope = @q.result
			@pagy, @asset_types = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @asset_type = AssetType.new
    end

    def create
      authorize :authorization, :create?

      @asset_type = AssetType.new(asset_type_params)

      respond_to do |format|
        if @asset_type.save
          format.html { redirect_to admin_asset_types_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.asset_type"))}
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
				if @asset_type.update(asset_type_params)
					format.html { redirect_to admin_asset_types_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset_type")) }
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

      asset_type_ids = params[:asset_type_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				asset_types = AssetType.where(id: asset_type_ids)

				asset_types.each do |asset_type|
					unless asset_type.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = asset_types.map { |asset_type| asset_type.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_asset_types_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_asset_types_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.asset_type")) }
					end
				end
			end
    end


    private

      def asset_type_params
        params.expect(asset_type: [ :name, :description ])
      end

      def set_asset_type
        @asset_type = AssetType.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_ASS_COM_ASSET_TYPE
      end
  end
end