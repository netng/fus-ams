module Admin
  class AssetItemTypesController < ApplicationAdminController
    before_action :set_asset_item_type, only: [:edit, :update, :destroy]
    before_action :set_function_access_code

    def index
      authorize :authorization, :index?

      @q = AssetItemType.ransack(params[:q])
			scope = @q.result.includes(:asset_type)
			@pagy, @asset_item_types = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @asset_item_type = AssetItemType.new
    end

    def create
      authorize :authorization, :create?

      @asset_item_type = AssetItemType.new(asset_item_type_params)

      respond_to do |format|
        if @asset_item_type.save
          format.html { redirect_to admin_asset_item_types_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.asset_item_type"))}
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
				if @asset_item_type.update(asset_item_type_params)
					format.html { redirect_to admin_asset_item_types_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset_item_type")) }
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

      asset_item_type_ids = params[:asset_item_type_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				asset_item_types = AssetItemType.where(id: asset_item_type_ids)

				asset_item_types.each do |asset_item_type|
					unless asset_item_type.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = asset_item_types.map { |asset_item_type| asset_item_type.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_asset_item_types_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_asset_item_types_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.asset_item_type")) }
					end
				end
			end
    end


    private

      def asset_item_type_params
        params.expect(asset_item_type: [ :name, :description, :asset_type_id ])
      end

      def set_asset_item_type
        @asset_item_type = AssetItemType.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_ASS_COM_ASSET_ITEM_TYPE
      end
  end
end