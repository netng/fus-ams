class ExportAssetJob < ApplicationJob
  queue_as :low_priority

  def perform(account, ransack_params, file_name)
    site_name = "All"
    site_id = ransack_params["site_id"]

    # logger
    logger.debug "Starting export assets data to excel. job_id: #{self.job_id} - At #{Time.now}"
    puts "Starting export assets data to excel. job_id: #{self.job_id} - At #{Time.now}"

    q = Asset.ransack(ransack_params)
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
      site_name = Site.find(site_id)&.name
    end

    assets = scope


    package = Axlsx::Package.new
    wb = package.workbook

    s = wb.styles
    bold_text = s.add_style b: true
    header = s.add_style b: true, bg_color: "000080", fg_color: "ffffff", alignment: { vertical: :center }

    wb.add_worksheet(name: "Assets") do |sheet|
      sheet.add_row
      sheet.add_row [ "Report name", "Assets report" ], style: [ bold_text, nil ]
      sheet.add_row [ "Generated at", Time.now.strftime("%d-%m-%Y %H:%M"), "By", account.username.capitalize ], style: [ bold_text, nil, bold_text, nil ], types: [ nil, :string, nil, nil ]

      sheet.add_row

      sheet.add_row [ "Site", site_name ], style: [ bold_text, nil ], types: [ nil, :string ]
      sheet.add_row [ "Total asset", assets.count ], style: [ bold_text, nil ], types: [ nil, :string ]

      sheet.add_row
      sheet.add_row


      # Tambahkan Header
      # Freeze header
      sheet.sheet_view.pane do |pane|
        pane.state = :frozen
        pane.y_split = 9
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

      sheet.auto_filter = "A9:P9"

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
            "schedule TODO",
            asset_spec,
            asset.asset_model.asset_type.name,
            asset.asset_model.brand.name,
            asset.project&.name
          ]
        end
      end
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
      finished_at: Time.now
    )

    logger.debug "Export finished job_id: #{self.job_id} - At #{Time.now}. File path #{report_path}"
    puts "Export finished job_id: #{self.job_id} - At #{Time.now}. File path #{report_path}"
  end
end
