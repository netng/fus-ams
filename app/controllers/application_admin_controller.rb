class ApplicationAdminController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Authentication
  include Authorization
  include SetCurrentRequestDetails
  include Pagy::Backend
  include Menuable

  rescue_from Aws::S3::Errors::XMinioAdminBucketQuotaExceeded, with: :quota_exceeded_errors

  layout "application_admin"

  private
    def show_record_errors(exception)
      redirect_back_or_to root_url, alert: exception.record.errors.full_messages.to_sentence
    end

    def quota_exceeded_errors
      flash.now[:alert] = "Your storage is full"
      render turbo_stream: turbo_stream.replace(
        "flash-message",
        partial: "shared/flash",
        locals: { flash: flash }
      )
    end
end
