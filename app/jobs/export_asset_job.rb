class ExportAssetJob < ApplicationJob
  queue_as :low_priority

  after_perform do |job|
    update_export_status
  end

  def perform(account, ransack_params, file_name, sheet_password, function_access_code)
    # site_name = "All"
    site_id = ransack_params["site_id"]

    # logger
    logger.debug "Starting export assets data to excel. job_id: #{self.job_id} - At #{Time.now}"
    puts "Starting export assets data to excel. job_id: #{self.job_id} - At #{Time.now}"

    q = nil
    if account.site.site_default.blank?
      q = Asset.joins(:site).where(sites: { id: account.site.id })
        .or(Asset.joins(:site).where(sites: { parent_site: account.site }))
        .ransack(ransack_params)

    else
      q = Asset.ransack(ransack_params)
    end


    q.sorts = [ "tagging_id asc" ] if q.sorts.empty?

    scope = q.result.includes(
      :project,
      :site,
      :asset_model,
      :asset_class,
      :delivery_order,
      :components,
      :softwares,
      :user_asset,
      asset_model: :brand,
    )

    if site_id.present?
      site_ids = Site.where(id: site_id)
                      .or(Site.where(parent_site_id: site_id))
                      .pluck(:id)

      scope = scope.where(site_id: site_ids)
      # site_name = Site.find(site_id)&.name
    end

    assets = scope

    package = Axlsx::Package.new
    wb = package.workbook

    s = wb.styles
    # bold_text = s.add_style b: true
    header = s.add_style b: true, bg_color: "000080", fg_color: "ffffff", alignment: { vertical: :center }

    wb.add_worksheet(name: "Assets") do |sheet|
      unless sheet_password.blank?
        sheet.sheet_protection do |protection|
          protection.password = sheet_password
        end
      end


      # sheet.add_row
      # sheet.add_row [ "Report name", "Assets report" ], style: [ bold_text, nil ]
      # sheet.add_row [ "Generated at", Time.now.strftime("%d-%m-%Y %H:%M"), "By", account.username.capitalize ], style: [ bold_text, nil, bold_text, nil ], types: [ nil, :string, nil, nil ]

      # sheet.add_row

      # sheet.add_row [ "Site", site_name ], style: [ bold_text, nil ], types: [ nil, :string ]
      # sheet.add_row [ "Total asset", assets.count ], style: [ bold_text, nil ], types: [ nil, :string ]

      # sheet.add_row
      # sheet.add_row


      # Tambahkan Header
      # Freeze header
      sheet.sheet_view.pane do |pane|
        pane.state = :frozen
        pane.y_split = 1
      end

      sheet.add_row [
        "Tagging Id",
        "Model",
        "Serial No.",
        "User Name",
        "Aztec Code",
        "Email",
        "Site",
        "Site Group",
        "DO Ref.",
        "DO Date",
        "Warranty Exp.",
        "Schedule",
        "Specifications",
        "Asset Type",
        "Brand",
        "Project"
      ], style: header


      # Tambahkan Data
      assets.find_in_batches do |asset_batch|
        asset_batch.each do |asset|
          asset_spec = asset.components.joins(:component_type).where(component_type: { id_component_type: 2 }).first&.name
          sheet.add_row [
            asset.tagging_id,
            asset.asset_model&.name,
            asset.cpu_sn,
            asset.user_asset&.username,
            asset.user_asset&.aztec_code,
            asset.user_asset&.email,
            asset.site&.name,
            asset.site.site_group.name,
            asset.delivery_order&.number,
            asset.delivery_order&.date&.strftime("%d-%m-%Y"),
            asset.delivery_order&.warranty_expired&.strftime("%d-%m-%Y"),
            asset.schedule,
            asset_spec,
            asset.asset_model.asset_type.name,
            asset.asset_model.brand.name,
            asset.project&.name
          ]
        end
      end

      row_count = 1 + assets.size # Baris header dimulai dari A9
      sheet.auto_filter = "A1:P#{row_count}"
      sheet.auto_filter.sort_state.add_sort_condition column_index: 0, order: :asc
    end


    file_path = Rails.root.join("tmp", "exports", file_name)
    if !File.directory?(File.dirname(file_path))
      FileUtils.mkdir(File.dirname(file_path))
    end

    package.serialize(file_path)

    report_path = Rails.root.join("public", "reports")
    FileUtils.mv(file_path, report_path)

    ReportQueue.where(job_id: self.job_id).update!(
      file_path: Rails.root.join(report_path, file_name),
      finished_at: Time.now,
      data_count: assets.count
    )


    puts "current account : #{self.arguments.first}"
    logger.debug "Export finished job_id: #{self.job_id} - At #{Time.now}. File path #{report_path}"
    puts "Export finished job_id: #{self.job_id} - At #{Time.now}. File path #{report_path}"
  end

  private
    def current_account
      @current_account ||= Account.find(self.arguments.first.id)
    end

    def update_export_status
      function_access_code = self.arguments[4]

      pundit_context = {
        account: current_account,
        function_access_code: function_access_code
      }

      can_destroy = Pundit.policy(pundit_context, [ :admin, :authorization ]).destroy?

      report_queue = current_account.report_queues.where(job_id: self.job_id).first

      Turbo::StreamsChannel.broadcast_replace_to(
        "account_#{current_account.id}",
        target: "report_queue_#{report_queue.id}",
        partial: "admin/entries/assets/report_queues/turbo_report_queue",
        locals: { report_queue: report_queue, can_destroy: can_destroy }
      )
    end
end
