class RequestForPurchaseDetail < ApplicationRecord
  belongs_to :currency, optional: true
  belongs_to :request_for_purchase, optional: true
end
