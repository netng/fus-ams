module Publicable
  extend ActiveSupport::Concern

	included do
		include Authentication
		skip_before_action :authenticate
		skip_before_action :authenticate_user!
	end
end