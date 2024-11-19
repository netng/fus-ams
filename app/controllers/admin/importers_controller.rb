class Admin::ImportersController < ApplicationAdminController
  def index
    skip_authorization
  end

  def site_stats_import
    skip_authorization
    allowed_extension = [ ".xlsx", ".csv" ]
    file = params[:file]

    if file.present?
      if !allowed_extension.include?(File.extname(file.original_filename))
        return redirect_back_or_to admin_importers_path, alert: t("custom.errors.invalid_allowed_extension")
      end

      # buka file menggunakan roo
      xlsx = Roo::Spreadsheet.open(file.path)

      # ambil sheet pertama
      sheet = xlsx.sheet(0)

      site_stat_attributes_headers = {
        id_site_stat: "Site stat id",
        name: "Name",
        description: "Description"
      }

      ActiveRecord::Base.transaction do
        begin
          sheet.parse(site_stat_attributes_headers).each do |row|
            site_stat = SiteStat.new(
              id_site_stat: row[:id_site_stat],
              name: row[:name],
              description: row[:description]
            )

            unless site_stat.save
              error_message = site_stat.errors.details.map do |field, error_details|
                error_details.map do |error|
                  "[#{t("custom.errors.import_failed")}] - #{field.to_s.titleize} #{error[:value]} #{I18n.t('errors.messages.taken')}"
                end
              end.flatten.join("")

              redirect_to admin_importers_path, alert: error_message
              raise ActiveRecord::Rollback
            end
          end
        rescue Roo::HeaderRowNotFoundError => e
          return redirect_to admin_importers_path, alert: t("custom.errors.invalid_import_template", errors: e)
        end

        respond_to do |format|
          format.html { redirect_to admin_importers_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.site_stat")) }
        end
      end
    else
      redirect_back_or_to admin_importers_path, alert: t("custom.flash.alerts.select_file")
    end
  end

  def assets_import
    skip_authorization

    allowed_extension = [ ".xlsx", ".csv" ]
    file = params[:file]
    data = []
    batch_size = 1000
    maybe_error = false

    start_time = Time.now

    created_by = Current.account.username
    request_id = Current.request_id
    user_agent = Current.user_agent
    ip_address = Current.ip_address

    if file.present?
      if !allowed_extension.include?(File.extname(file.original_filename))
        return redirect_back_or_to admin_importers_path, alert: t("custom.errors.invalid_allowed_extension")
      end

      xlsx = Roo::Spreadsheet.open(file.path)

      sheet = xlsx.sheet(0)

      asset_attributes_headers = {
        tagging_id: "Tagging id",
        tagging_date: "Tagging date",
        user_asset_id: "User asset id",
        site_id: "Site id",
        asset_model_id: "Asset model id",
        cpu_sn: "Cpu sn",
        monitor_sn: "Monitor sn",
        keyboard_sn: "Keyboard sn",
        delivery_order_number: "DO number",
        description: "Description",
        computer_name: "Computer name",
        computer_ip: "Computer ip",
        shipping_date: "Shipping date",
        project_id: "Project id",
        asset_class_id: "Asset class id"

      }

      begin
        ActiveRecord::Base.transaction do
          sheet.parse(asset_attributes_headers).each do |row|
            user_asset = UserAsset.find_by_id_user_asset(row[:user_asset_id]&.strip)
            site = Site.find_by_id_site(row[:site_id]&.strip)
            asset_model = AssetModel.find_by_id_asset_model(row[:asset_model_id]&.strip)
            delivery_order = DeliveryOrder.find_by_number(row[:delivery_order_number]&.strip)
            project = Project.find_by_id_project(row[:project_id]&.strip)
            asset_class = AssetClass.find_by_id_asset_class(row[:asset_class_id]&.strip)

            if user_asset.nil?
              maybe_error = true
              logger.debug "request_id: #{request.request_id} - Asset: #{row[:tagging_id]} - reason: user asset `#{row[:user_asset_id]}` is not found"
              redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.user_asset"), id: row[:user_asset_id])
              raise ActiveRecord::Rollback
              return
            end

            if site.nil?
              maybe_error = true
              logger.debug "request_id: #{request.request_id} - Asset: #{row[:tagging_id]} - reason: site `#{row[:site_id]}` is not found"
              redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.site"), id: row[:site_id])
              raise ActiveRecord::Rollback
              return
            end

            if asset_model.nil?
              maybe_error = true
              logger.debug "request_id: #{request.request_id} - Asset: #{row[:tagging_id]} - reason: asset model `#{row[:asset_model_id]}` is not found"
              redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_model"), id: row[:asset_model_id])
              raise ActiveRecord::Rollback
              return
            end

            if project.nil?
              maybe_error = true
              logger.debug "request_id: #{request.request_id} - Asset : #{row[:tagging_id]} - reason: project `#{row[:project_id]}` is not found"

              redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.project"), id: row[:project_id])
              raise ActiveRecord::Rollback
              return
            end

            if row[:delivery_order_number].present?
              if delivery_order.nil?
                maybe_error = true
                logger.debug "request_id: #{request.request_id} - Asset : #{row[:tagging_id]} - reason: DO number `#{row[:delivery_order_number]}` is not found"

                redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.delivery_order"), id: row[:delivery_order_number])
                raise ActiveRecord::Rollback
                return
              end
            end

            if row[:asset_class_id].present?
              if asset_class.nil?
                maybe_error = true
                logger.debug "request_id: #{request.request_id} - Asset : #{row[:tagging_id]} - reason: Asset class `#{row[:asset_class_id]}` is not found"

                redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.asset_class"), id: row[:asset_class_id])
                raise ActiveRecord::Rollback
                return
              end
            end

            data << {
              tagging_id: row[:tagging_id],
              tagging_date: row[:tagging_date],
              user_asset_id: user_asset.id,
              site_id: site.id,
              asset_model_id: asset_model.id,
              cpu_sn: row[:cpu_sn],
              monitor_sn: row[:monitor_sn],
              keyboard_sn: row[:keyboard_sn],
              delivery_order_id: delivery_order&.id,
              description: row[:description],
              computer_name: row[:computer_name],
              computer_ip: row[:computer_ip],
              shipping_date: row[:shipping_date],
              project_id: project.id,
              asset_class_id: asset_class&.id,

              created_by: created_by,
              request_id: request_id,
              user_agent: user_agent,
              ip_address: ip_address
            }

            if data.size >= batch_size
              Asset.insert_all!(data)
              data.clear
            end
          end

          Asset.insert_all!(data) unless data.empty?
        end

      rescue Roo::HeaderRowNotFoundError => e
        return redirect_to admin_importers_path, alert: t("custom.errors.invalid_import_template", errors: e)


      # Penanganan untuk duplikat data
      rescue ActiveRecord::RecordNotUnique => e
        logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
        duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
        duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
        humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
        return redirect_back_or_to admin_importers_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

      # penangan error null violation
      rescue ActiveRecord::NotNullViolation => e
        logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
        error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
        error_row = data.find { |r| r[error_column.to_sym].nil? }

        error_message = "#{t('activerecord.attributes.asset.' + error_column)} " \
          "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
        return redirect_back_or_to admin_importers_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

      # Penanganan umum untuk semua jenis error lainnya
      rescue => e
        logger.error "#{Current.request_id} - General error during import: #{e.message}"
        return redirect_back_or_to admin_importers_path, alert: t("custom.errors.general_error")

      end

      unless maybe_error
        logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
        redirect_to admin_importers_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset"))
        nil
      end

    else
      redirect_back_or_to admin_importers_path, alert: t("custom.flash.alerts.select_file")
    end
  end

  def asset_components_import
    skip_authorization

    allowed_extension = [ ".xlsx", ".csv" ]
    file = params[:file]
    data = []
    batch_size = 1000
    maybe_error = false

    start_time = Time.now

    created_by = Current.account.username
    request_id = Current.request_id
    user_agent = Current.user_agent
    ip_address = Current.ip_address

    if file.present?
      if !allowed_extension.include?(File.extname(file.original_filename))
        return redirect_back_or_to admin_importers_path, alert: t("custom.errors.invalid_allowed_extension")
      end

      xlsx = Roo::Spreadsheet.open(file.path)

      sheet = xlsx.sheet(0)

      asset_attributes_headers = {
        tagging_id: "Tagging id",
        component_id: "Component id",
        serial_number: "Serial number"

      }

      begin
        ActiveRecord::Base.transaction do
          sheet.parse(asset_attributes_headers).each do |row|
            asset = Asset.find_by_tagging_id(row[:tagging_id]&.strip)
            component = Component.find_by_id_component(row[:component_id]&.strip)

            if row[:tagging_id].present?
              if asset.nil?
                # maybe_error = true
                logger.debug "request_id: #{request.request_id} - Asset: #{row[:tagging_id]} - reason: asset `#{row[:tagging_id]}` is not found"
                # redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.user_asset"), id: row[:tagging_id])
                # raise ActiveRecord::Rollback
                # return

                asset = Asset.create(
                  tagging_date: Date.today,
                  tagging_id: row[:tagging_id].strip.upcase,
                  project_id: Project.find_by_id_project("SAFETY-NET").id,
                  site_id: Site.find_by_id_site("SAFETY-NET").id,
                  asset_model_id: AssetModel.find_by_id_asset_model("SAFETY-NET").id,
                  user_asset_id: UserAsset.find_by_id_user_asset("FUSDEV").id,
                  created_by: created_by,
                  request_id: request_id,
                  user_agent: user_agent,
                  ip_address: ip_address
                )
              end
            end

            if component.nil?
              # maybe_error = true
              logger.debug "request_id: #{request.request_id} - Asset: #{row[:tagging_id]} - reason: component `#{row[:component_id]}` is not found"
              # redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.component"), id: row[:component_id])
              # raise ActiveRecord::Rollback
              # return

              component = Component.create(
                  id_component: row[:component_id].strip.upcase,
                  component_type_id: ComponentType.find_by_id_component_type("7"),
                  description: "safety net",
                  created_by: created_by,
                  request_id: request_id,
                  user_agent: user_agent,
                  ip_address: ip_address
                )
            end

            data << {
              asset_id: asset.id,
              component_id: component.id,
              serial_number: row[:serial_number],
              created_by: created_by,
              request_id: request_id,
              user_agent: user_agent,
              ip_address: ip_address
            }

            if data.size >= batch_size
              AssetComponent.insert_all!(data)
              data.clear
            end
          end

          AssetComponent.insert_all!(data) unless data.empty?
        end

      rescue Roo::HeaderRowNotFoundError => e
        return redirect_to admin_importers_path, alert: t("custom.errors.invalid_import_template", errors: e)


      # Penanganan untuk duplikat data
      rescue ActiveRecord::RecordNotUnique => e
        logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
        duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
        duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
        humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
        return redirect_back_or_to admin_importers_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

      # penangan error null violation
      rescue ActiveRecord::NotNullViolation => e
        logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
        error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
        error_row = data.find { |r| r[error_column.to_sym].nil? }

        error_message = "#{t('activerecord.attributes.asset.' + error_column)} " \
          "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
        return redirect_back_or_to admin_importers_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

      # Penanganan umum untuk semua jenis error lainnya
      rescue => e
        logger.error "#{Current.request_id} - General error during import: #{e.message}"
        return redirect_back_or_to admin_importers_path, alert: t("custom.errors.general_error")

      end

      unless maybe_error
        logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
        redirect_to admin_importers_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset"))
        nil
      end

    else
      redirect_back_or_to admin_importers_path, alert: t("custom.flash.alerts.select_file")
    end
  end

  def asset_softwares_import
    skip_authorization

    allowed_extension = [ ".xlsx", ".csv" ]
    file = params[:file]
    data = []
    batch_size = 1000
    maybe_error = false

    start_time = Time.now

    created_by = Current.account.username
    request_id = Current.request_id
    user_agent = Current.user_agent
    ip_address = Current.ip_address

    if file.present?
      if !allowed_extension.include?(File.extname(file.original_filename))
        return redirect_back_or_to admin_importers_path, alert: t("custom.errors.invalid_allowed_extension")
      end

      xlsx = Roo::Spreadsheet.open(file.path)

      sheet = xlsx.sheet(0)

      asset_softwares_attributes = {
        sequence_number: "Sequence number",
        tagging_id: "Tagging id",
        software_id: "Software id",
        license: "License"

      }

      begin
        ActiveRecord::Base.transaction do
          sheet.parse(asset_softwares_attributes).each do |row|
            asset = Asset.find_by_tagging_id(row[:tagging_id]&.strip)
            software = Software.find_by_id_software(row[:software_id]&.strip)

            if asset.nil?
              maybe_error = true
              logger.debug "request_id: #{request.request_id} - Asset: #{row[:tagging_id]} - reason: asset `#{row[:tagging_id]}` is not found"
              # redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.user_asset"), id: row[:tagging_id])
              # raise ActiveRecord::Rollback
              # return

              asset = Asset.create(
                tagging_date: Date.today,
                tagging_id: row[:tagging_id].strip.upcase,
                project_id: Project.find_by_id_project("SAFETY-NET").id,
                site_id: Site.find_by_id_site("SAFETY-NET").id,
                asset_model_id: AssetModel.find_by_id_asset_model("SAFETY-NET").id,
                user_asset_id: UserAsset.find_by_id_user_asset("FUSDEV").id,
                created_by: created_by,
                request_id: request_id,
                user_agent: user_agent,
                ip_address: ip_address
              )
            end

            if software.nil?
              maybe_error = true
              logger.debug "request_id: #{request.request_id} - Asset: #{row[:tagging_id]} - reason: software `#{row[:software_id]}` is not found"
              # redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.component"), id: row[:component_id])
              # raise ActiveRecord::Rollback
              # return

              software = Software.create(
                  id_software: row[:software_id].strip.upcase,
                  name: "#{row[:software_id]} (safety-net)",
                  description: "safety net",
                  created_by: created_by,
                  request_id: request_id,
                  user_agent: user_agent,
                  ip_address: ip_address
                )
            end

            data << {
              asset_id: asset.id,
              software_id: software.id,
              license: row[:license],
              sequence_number: row[:sequence_number],
              created_by: created_by,
              request_id: request_id,
              user_agent: user_agent,
              ip_address: ip_address
            }

            if data.size >= batch_size
              AssetSoftware.insert_all!(data)
              data.clear
            end
          end

          AssetSoftware.insert_all!(data) unless data.empty?
        end

      rescue Roo::HeaderRowNotFoundError => e
        return redirect_to admin_importers_path, alert: t("custom.errors.invalid_import_template", errors: e)


      # Penanganan untuk duplikat data
      rescue ActiveRecord::RecordNotUnique => e
        logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
        duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
        duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
        humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
        return redirect_back_or_to admin_importers_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

      # penangan error null violation
      rescue ActiveRecord::NotNullViolation => e
        logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
        error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
        error_row = data.find { |r| r[error_column.to_sym].nil? }

        error_message = "#{t('activerecord.attributes.asset.' + error_column)} " \
          "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
        return redirect_back_or_to admin_importers_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

      # Penanganan umum untuk semua jenis error lainnya
      rescue => e
        logger.error "#{Current.request_id} - General error during import: #{e.message}"
        return redirect_back_or_to admin_importers_path, alert: t("custom.errors.general_error")

      end

      unless maybe_error
        logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
        redirect_to admin_importers_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset"))
        nil
      end

    else
      redirect_back_or_to admin_importers_path, alert: t("custom.flash.alerts.select_file")
    end
  end


  def asset_classes_import
    skip_authorization

    allowed_extension = [ ".xlsx", ".csv" ]
    file = params[:file]
    data = []
    batch_size = 1000
    maybe_error = false

    start_time = Time.now

    created_by = Current.account.username
    request_id = Current.request_id
    user_agent = Current.user_agent
    ip_address = Current.ip_address

    if file.present?
      if !allowed_extension.include?(File.extname(file.original_filename))
        return redirect_back_or_to admin_importers_path, alert: t("custom.errors.invalid_allowed_extension")
      end

      xlsx = Roo::Spreadsheet.open(file.path)

      sheet = xlsx.sheet(0)

      asset_attributes_headers = {
        id_asset_class: "Asset class id",
        name: "Name",
        project_id: "Project id"

      }

      begin
        ActiveRecord::Base.transaction do
          sheet.parse(asset_attributes_headers).each do |row|
            project = Project.find_by_id_project(row[:project_id]&.strip)

            if project.nil?
              maybe_error = true
              redirect_back_or_to admin_importers_path, alert: t("custom.errors.activerecord_object_not_found", model: t("activerecord.models.project"), id: row[:project_id])
              raise ActiveRecord::Rollback
              return
            end

            data << {
              id_asset_class: row[:id_asset_class],
              name: row[:name],
              project_id: project.id,

              created_by: created_by,
              request_id: request_id,
              user_agent: user_agent,
              ip_address: ip_address
            }

            if data.size >= batch_size
              AssetClass.insert_all!(data)
              data.clear
            end
          end

          AssetClass.insert_all!(data) unless data.empty?
        end

      rescue Roo::HeaderRowNotFoundError => e
        return redirect_to admin_importers_path, alert: t("custom.errors.invalid_import_template", errors: e)


      # Penanganan untuk duplikat data
      rescue ActiveRecord::RecordNotUnique => e
        logger.error "#{Current.request_id} - Duplicate data: #{e.message}"
        duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
        duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
        humanized_message = t("custom.errors.duplicate_data", field: duplicate_field.humanize, value: duplicate_value)
        return redirect_back_or_to admin_importers_path, alert: "#{humanized_message}. #{t('custom.errors.resolve_duplicate')}."

      # penangan error null violation
      rescue ActiveRecord::NotNullViolation => e
        logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
        error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
        error_row = data.find { |r| r[error_column.to_sym].nil? }

        error_message = "#{t('activerecord.attributes.asset.' + error_column)} " \
          "#{I18n.t('errors.messages.blank')} (row: #{error_row.inspect})"
        return redirect_back_or_to admin_importers_path, alert: "#{t('custom.errors.import_failed')}: #{error_message}"

      # Penanganan umum untuk semua jenis error lainnya
      rescue => e
        logger.error "#{Current.request_id} - General error during import: #{e.message}"
        return redirect_back_or_to admin_importers_path, alert: t("custom.errors.general_error")

      end

      unless maybe_error
        logger.debug "#{Current.request_id} - IMPORT START TIME: #{start_time}, IMPORT END TIME: #{Time.now}"
        redirect_to admin_importers_path, notice: t("custom.flash.notices.successfully.imported", model: t("activerecord.models.asset"))
        nil
      end

    else
      redirect_back_or_to admin_importers_path, alert: t("custom.flash.alerts.select_file")
    end
  end
end
