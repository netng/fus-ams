module Admin::Charts
  class ChartsController < ApplicationAdminController
    def asset_registrations
      skip_authorization
      render json: Asset.group_by_year(:tagging_date).count
    end

    def asset_projects
      skip_authorization
      render json: Asset.group(:project).count.map { |k, v| [ [ k.name ], v ] }
    end
  end
end
