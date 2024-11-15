module Admin::Setups
  class RolesController < ApplicationAdminController
    before_action :set_role, only: [ :edit, :update, :destroy ]

    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :new, :create, :edit, :update ]
    before_action :set_previous_url


    def index
      authorize :authorization, :index?

      @q = Role.ransack(params[:q])
      @q.sorts = [ "name asc" ] if @q.sorts.empty?
      scope = @q.result
      @pagy, @roles = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @role = Role.new
    end

    def create
      authorize :authorization, :create?

      @role = Role.new(role_params)

      respond_to do |format|
        if @role.save
          format.html {
            redirect_to admin_roles_path,
            notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.role"))
          }
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
        if @role.update(role_params)
          format.html {
            redirect_to admin_roles_path,
            notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.role"))
          }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize :authorization, :delete?
    end

    def destroy_many
      authorize :authorization, :destroy?

      role_ids = params[:role_ids]

      ActiveRecord::Base.transaction do
        roles = Role.where(id: role_ids)

        roles.each do |role|
          unless role.destroy
            redirect_to admin_roles_path, alert: "#{role.errors.full_messages.join("")} - #{t('activerecord.models.role')} id: #{role.name}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_roles_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.role")) }
        end
      end
    end

    private
      def role_params
        params.expect(role: [
          :name, :description, :active,
          role_function_accesses_attributes: [ [
            :id,
            :function_access_id,
            :allow_read,
            :allow_create,
            :allow_update,
            :allow_delete,
            :_destroy
          ] ]
        ])
      end

      def set_previous_url
        @previous_url = admin_roles_path || root_path
      end

      def ensure_frame_response
        redirect_to admin_roles_path unless turbo_frame_request?
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ROLE
      end

      def set_role
        @role = Role.find(params[:id])
      end
  end
end
