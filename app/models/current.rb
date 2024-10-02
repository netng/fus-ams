class Current < ActiveSupport::CurrentAttributes
  attribute :account
  attribute :request_id, :user_agent, :ip_address

  reset { }

  def account=(account)
    super
  end
end