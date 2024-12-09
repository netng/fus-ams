module Admin::Setups
  class AccountsController < ApplicationAdminController
    before_action :set_account, only: [ :edit, :update, :destroy ]

    before_action :set_function_access_code
    before_action :ensure_frame_response, only: [ :new, :create, :edit, :update ]
    before_action :set_previous_url


    def index
      authorize :authorization, :index?

      @q = Account.ransack(params[:q])
      @q.sorts = [ "usernname asc" ] if @q.sorts.empty?
      scope = @q.result.includes(:role, :site)
      @pagy, @accounts = pagy(scope)
    end

    def new
      authorize :authorization, :create?

      @account = Account.new
    end

    def create
      authorize :authorization, :create?

      @account = Account.new(account_params)

      respond_to do |format|
        if @account.save
          format.html {
            redirect_to admin_accounts_path,
            notice: t("custom.flash.notices.successfully.created", model: t("activerecord.models.account"))
          }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize :authorization, :update?
      redirect_to admin_accounts_path if @account.default
    end

    def update
      authorize :authorization, :update?
      return redirect_to admin_accounts_path if @account.default

      respond_to do |format|
        if @account.update(account_params)
          format.html {
            redirect_to admin_accounts_path,
            notice: t("custom.flash.notices.successfully.updated", model: t("activerecord.models.account"))
          }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize :authorization, :delete?
      redirect_to admin_accounts_path if @account.default
    end

    def destroy_many
      authorize :authorization, :destroy?

      account_ids = params[:account_ids]

      ActiveRecord::Base.transaction do
        accounts = Account.where(id: account_ids)

        accounts.each do |account|
        return redirect_to admin_accounts_path if account.default

          unless account.destroy
            redirect_to admin_accounts_path, alert: "#{account.errors.full_messages.join("")} - #{t('activerecord.models.account')} id: #{account.username}"
            raise ActiveRecord::Rollback
          end
        end

        respond_to do |format|
          format.html { redirect_to admin_accounts_path, notice: t("custom.flash.notices.successfully.destroyed", model: t("activerecord.models.account")) }
        end
      end
    end

    private
      def account_params
        params.expect(account: [ :username, :email, :password, :role_id, :site_id, :active ])
      end

      def set_previous_url
        @previous_url = request.referer || admin_accounts_path || root_path
      end

      def ensure_frame_response
        redirect_to admin_accounts_path unless turbo_frame_request?
      end

      def set_function_access_code
        @function_access_code = FunctionAccessConstant::FA_ACCOUNT
      end

      def set_account
        @account = Account.find(params[:id])
      end
  end
end
