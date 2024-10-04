module Authorization
  extend ActiveSupport::Concern
  include Pundit::Authorization

  included do
    after_action :verify_authorized
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end


  def authorize(record, query = nil)
    super([:admin, record], query)
  end

  def pundit_user
    {account: current_account, function_access_code: @function_access_code}
  end

  private

    def user_not_authorized(exception)
      policy_name = exception.policy.class.to_s.underscore
      flash[:alert] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
      redirect_back_or_to(admin_path)
    end
end