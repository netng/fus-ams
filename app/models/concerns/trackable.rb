module Trackable
  extend ActiveSupport::Concern

  included do
    before_create :set_current_request_details
  end

  private
    def set_current_request_details
      self.created_by = Current.account.username
      self.request_id = Current.request_id
      self.user_agent = Current.user_agent
      self.ip_address = Current.ip_address
    end
end