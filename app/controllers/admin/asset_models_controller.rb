module Admin
  class AssetModelsController < ApplicationAdminController
    before_action :set_asset_model, only: [:edit, :update, :destroy]
    before_action :set_function_access_code
    before_action :find_dependent, only: [:index]

    def index
      authorize :authorization, :index?

      @q = AssetModel.ransack(params[:q])
			scope = @q.result.includes(:brand, :asset_type, :asset_item_type).order(created_at: :desc)
			@pagy, @asset_models = pagy(scope)

      @asset_item_types = @asset_type&.asset_item_types || []
    end

    def new
      authorize :authorization, :create?

      @asset_model = AssetModel.new
      @asset_item_types = @asset_model.asset_type&.asset_item_types&.pluck(:name, :id)&.map { |name, id| [name.capitalize, id] } || []
    end

    def create
      authorize :authorization, :create?

      @asset_model = AssetModel.new(asset_model_params)
      @asset_item_types = @asset_model.asset_type&.asset_item_types&.pluck(:name, :id)&.map { |name, id| [name.capitalize, id] } || []

      respond_to do |format|
        if @asset_model.save
          format.html { redirect_to admin_asset_models_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.asset_model"))}
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize :authorization, :update?
      @asset_item_types = @asset_model.asset_type.asset_item_types.pluck(:name, :id).map { |name, id| [name.capitalize, id] }

    end

    def update
      authorize :authorization, :update?

      respond_to do |format|
				if @asset_model.update(asset_model_params)
					format.html { redirect_to admin_asset_models_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset_model")) }
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

      asset_model_ids = params[:asset_model_ids]
			deletion_failed = false

			ActiveRecord::Base.transaction do
				asset_models = AssetModel.where(id: asset_model_ids)

				asset_models.each do |asset_model|
					unless asset_model.destroy
						deletion_failed = true
						break
					end
				end
				
				respond_to do |format|
					if deletion_failed
						error_message = asset_models.map { |asset_model| asset_model.errors.full_messages }.flatten.uniq
						format.html { redirect_to admin_asset_models_path, alert: error_message.to_sentence }
					else
						format.html { redirect_to admin_asset_models_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.asset_model")) }
					end
				end
			end
    end

    def asset_item_types
      authorize :authorization, :read?

      if params[:query].present?
        query = params[:query].downcase
        asset_type = AssetType.find_by_name(query)
        asset_item_types = asset_type.asset_item_types
        render json: asset_item_types.pluck(:id, :name).map { |id, name| { id: id, name: name.capitalize } }
      else
        render json: [] 
      end
    end

    private

      def asset_model_params
        params.expect(asset_model: [ :name, :description, :brand_id, :asset_type_id, :asset_item_type_id ])
      end

      def set_asset_model
        @asset_model = AssetModel.find(params[:id])
      end

      def set_function_access_code
				@function_access_code = FunctionAccessConstant::FA_ASS_COM_ASSET_MODEL
      end

      def find_dependent
        if params[:q].present?
          @asset_type = AssetType.find_by_name(params[:q][:asset_type_name_cont]&.downcase)
          @asset_item_type = AssetItemType.find_by_name(params[:q][:asset_item_type_name_cont]&.downcase)
        end
      end

  end
end