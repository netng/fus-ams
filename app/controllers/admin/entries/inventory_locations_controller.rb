module Admin::Entries
  class InventoryLocationsController < ApplicationAdminController
    def index
      skip_authorization
    end
  end
end
