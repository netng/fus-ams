module Admin::AccessManagement
  class SetupsController < ApplicationAdminController
    def index
      skip_authorization
      #authorize :authorization, :index?
    end
  end
end
