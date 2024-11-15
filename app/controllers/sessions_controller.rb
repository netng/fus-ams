class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: [:new, :create]

  def new
  end

  def create
    @account = Account.find_by(username: params[:username].downcase)

    if @account&.active
      if @account&.authenticate(params[:password])
        login @account
        redirect_to admin_path, notice: t("custom.flash.notices.successfully.logged_in")
      end
    else
      flash.now[:alert] = t("custom.flash.alerts.invalid_credential")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to auth_sign_in_path
  end
end
