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
    logger.debug "FUNCTION ACCESS CODE: #{@function_access_code}"
    logger.debug "CURRENT ACCOUNT: #{current_account.username}"
    {account: current_account, function_access_code: @function_access_code}
  end

  private

    def user_not_authorized(exception)
      policy_name = exception.policy.class.to_s.underscore
      flash.now[:alert] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
      
      if turbo_frame_request?
        render turbo_stream: turbo_stream.replace("flash-message", partial: "shared/flash", locals: { flash: flash })
      else
        redirect_back_or_to(admin_path)
      end

    end
end