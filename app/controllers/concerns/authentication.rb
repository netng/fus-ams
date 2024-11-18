module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
    before_action :authenticate_user!

    helper_method :current_account
  end

  def login(account)
    reset_session
    session[:account_id] = account.id
  end

  def logout
    reset_session
  end

  def redirect_if_authenticated
    return unless account_sessions
    redirect_to admin_path
  end

  def authenticate_user!
    redirect_to auth_sign_in_path, alert: t("custom.flash.alerts.require_authentication") unless account_signed_in?
  end

  private
    def authenticate
      if (account = Account.find_by(id: session[:account_id]))
        Current.account = account
      else
        logout
      end
    end
    
    def account_signed_in?
      Current.account.present?
    end

    def current_account
      Current.account if account_signed_in?
    end
    

    def account_sessions
      session[:account_id]
    end
end