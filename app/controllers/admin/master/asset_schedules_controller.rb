module Admin::Master
  class AssetSchedulesController < ApplicationAdminController
    before_action :set_asset_schedule, only: [ :show, :edit, :update, :destroy ]
    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :show, :edit, :new, :create, :update ]
    before_action :set_previous_url


    def index
      authorize :authorization, :index?

      @q = AssetSchedule.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @asset_schedules = pagy(scope)
    end

    def show
      authorize :authorization, :read?
    end

    def new
      authorize :authorization, :create?

      @asset_schedule = AssetSchedule.new
    end

    def create
      authorize :authorization, :create?

      @asset_schedule = AssetSchedule.new(asset_schedule_params)

      respond_to do |format|
        if @asset_schedule.save
          format.html { redirect_to admin_asset_schedules_path, notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.asset_schedule")) }
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
        if @asset_schedule.update(asset_schedule_params)
          format.html { redirect_to admin_asset_schedules_path, notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.asset_schedule")) }
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

      asset_schedule_ids = params[:asset_schedule_ids]

      ActiveRecord::Base.transaction do
        asset_schedules = AssetSchedule.where(id: asset_schedule_ids)

        asset_schedules.each do |asset_schedule|
          unless asset_schedule.destroy
            redirect_to admin_asset_schedules_path, alert: "#{asset_schedule.errors.full_messages.join("")} - #{t('activerecord.models.asset_schedule')} id: #{asset_schedule.id_asset_schedule}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_asset_schedules_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.asset_schedule")) }
        end
      end
    end

    private
      def asset_schedule_params
        params.expect(asset_schedule: [ :name, :description ])
      end

      def set_asset_schedule
        @asset_schedule = AssetSchedule.find(params[:id])
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_MST_ASS_SCHEDULE
      end

      def ensure_frame_response
        redirect_to admin_asset_schedules_path unless turbo_frame_request?
      end

      def set_previous_url
        @previous_url = request.referer || admin_asset_schedules_path || root_path
      end
  end
end
