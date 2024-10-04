module Admin
  class HomeController < ApplicationAdminController
    def index
      skip_authorization
    end
  end
end
