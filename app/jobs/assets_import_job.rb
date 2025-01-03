class AssetsImportJob < ApplicationJob
  queue_as :default

  def perform(current_account, file_path)
    puts "processing import job id: #{self.job_id}"
    Turbo::StreamsChannel.broadcast_append_to(
      "account_#{current_account.id}",
      target: "asset_import_logs",
      partial: "admin/asset_management/assets/turbo_assets_import_logs",
      locals: { state: "preparing_file", error_message: nil, row_index: nil, tagging_id: nil }
    )

    error_message = nil
    data = []

    xlsx = Roo::Spreadsheet.open(file_path)

    sheet = xlsx.sheet(0)

    assets_attributes_headers = {
      tagging_id: "Tagging id *",
      project_id: "Project id *",
      site_id: "Site id *",
      asset_model_id: "Asset model id *",
      asset_class_id: "Asset class id",
      delivery_order_number: "DO number",
      schedule: "Schedule",
      computer_name: "Computer name",
      computer_ip: "Computer IP",
      cpu_sn: "CPU sn",
      monitor_sn: "Monitor sn",
      keyboard_sn: "Keyboard sn",
      shipping_date: "Shipping date",
      description: "Description",
      mouse_id: "Mouse id",
      mouse_sn: "Mouse sn",
      floopy_disk_id: "Floopy disk id",
      floopy_disk_sn: "Floopy disk sn",
      processor_id: "Processor id",
      processor_sn: "Processor sn",
      memory_id: "Memory id",
      memory_sn: "Memory sn",
      hardisk_id: "Hardisk id",
      hardisk_sn: "Hardisk sn",
      cd_dvd_rom_id: "CD / DVD rom id",
      cd_dvd_rom_sn: "CD / DVD rom sn",
      nic_id: "NIC id",
      nic_sn: "NIC sn",
      others_id: "Others id",
      others_sn: "Others sn"
    }

    begin
      ActiveRecord::Base.transaction do
        sheet.parse(assets_attributes_headers).each_with_index do |row, index|
          index = index + 1
          project = Project.find_by_id_project(row[:project_id]&.strip)
          site = Site.find_by_id_site(row[:site_id]&.strip)
          asset_model = AssetModel.find_by_id_asset_model(row[:asset_model_id]&.strip)
          asset_class = AssetClass.find_by_id_asset_class(row[:asset_class_id]&.strip)
          delivery_order = DeliveryOrder.find_by_number(row[:delivery_order_number]&.strip)
          comp_mouse = Component.find_by_id_component(row[:mouse_id]&.strip)
          comp_floopy_disk = Component.find_by_id_component(row[:floopy_disk_id]&.strip)
          comp_processor = Component.find_by_id_component(row[:processor_id]&.strip)
          comp_memory = Component.find_by_id_component(row[:memory_id]&.strip)
          comp_hardisk = Component.find_by_id_component(row[:hardisk_id]&.strip)
          comp_cd_dvd_rom = Component.find_by_id_component(row[:cd_dvd_rom_id]&.strip)
          comp_nic = Component.find_by_id_component(row[:nic_id]&.strip)
          comp_others = Component.find_by_id_component(row[:others_id]&.strip)
          asset = Asset.find_by_tagging_id(row[:tagging_id]&.strip&.upcase)
          schedule = AssetSchedule.find_by_name(row[:schedule]&.strip&.upcase)

          puts "tagging_id : #{row[:tagging_id]}"

          Turbo::StreamsChannel.broadcast_append_to(
            "account_#{current_account.id}",
            target: "asset_import_logs",
            partial: "admin/asset_management/assets/turbo_assets_import_logs",
            locals: { state: "preparing", error_message: nil, row_index: index + 1, tagging_id: row[:tagging_id] }
          )

          if row[:tagging_id].nil?
            error_message= "Tagging id must exists at row #{index + 1}"
            # raise ActiveRecord::Rollback
            raise RollbackError, error_message
          end

          if asset.present?
            error_message = "Duplicate data found: 'Tagging id' with value '#{row[:tagging_id]}' already exists"
            # raise ActiveRecord::Rollback
            raise RollbackError, error_message
          end

          if project.nil?
            error_message = "Project id `#{row[:project_id]}` is not found at row #{index + 1}"
            # raise ActiveRecord::Rollback
            raise RollbackError, error_message
          end

          if site.nil?
            error_message = "Site id `#{row[:site_id]}` is not found at row #{index + 1}"
            # raise ActiveRecord::Rollback
            raise RollbackError, error_message
          end

          if asset_model.nil?
            error_message = "Asset Model id `#{row[:asset_model_id]}` is not found at row #{index + 1}"
            # raise ActiveRecord::Rollback
            raise RollbackError, error_message
          end

          if row[:asset_class_id].present?
            if asset_class.nil?
              error_message = "Asset Class id `#{row[:asset_class_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              raise RollbackError, error_message
            end
          end

          if row[:delivery_order_number].present?
            if delivery_order.nil?
              error_message = "Delivery Order id `#{row[:delivery_order_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          if row[:mouse_id].present?
            if comp_mouse.nil?
              error_message = "Asset Component id `#{row[:mouse_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          if row[:floopy_disk_id].present?
            if comp_floopy_disk.nil?
              error_message = "Asset Component id `#{row[:floopy_disk_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          if row[:processor_id].present?
            if comp_processor.nil?
              error_message = "Asset Component id `#{row[:processor_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          if row[:memory_id].present?
            if comp_memory.nil?
              error_message = "Asset Component id `#{row[:memory_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          if row[:hardisk_id].present?
            if comp_hardisk.nil?
              error_message = "Asset Component id `#{row[:hardisk_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          if row[:cd_dvd_rom_id].present?
            if comp_cd_dvd_rom.nil?
              error_message = "Asset Component id `#{row[:cd_dvd_rom_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          if row[:nic_id].present?
            if comp_nic.nil?
              error_message = "Asset Component id `#{row[:nic_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          if row[:others_id].present?
            if comp_others.nil?
              error_message = "Asset Component id `#{row[:others_id]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          if row[:schedule].present?
            if schedule.nil?
              error_message = "Schedule id `#{row[:schedule]}` is not found at row #{index + 1}"
              # raise ActiveRecord::Rollback
              # return
              raise RollbackError, error_message
            end
          end

          user_asset_default = UserAsset
            .find_by_id_user_asset(
              SiteDefault.find_by_site_id(site.id).id_user_site_default
              ) unless site.nil?

          asset = Asset.new(
            tagging_date: Time.now,
            user_asset_id: user_asset_default&.id,
            tagging_id: row[:tagging_id].strip.upcase,
            project_id: project&.id,
            site_id: site&.id,
            asset_model_id: asset_model&.id,
            asset_class_id: asset_class&.id,
            delivery_order_id: delivery_order&.id,
            asset_schedule_id: schedule&.id,
            computer_name: row[:computer_name],
            computer_ip: row[:computer_ip],
            cpu_sn: row[:cpu_sn],
            monitor_sn: row[:monitor_sn],
            keyboard_sn: row[:keyboard_sn],
            shipping_date: row[:shipping_date],
            description: row[:description],
            created_by: current_account.username
          )

          asset.asset_components.build([
            { component_id: comp_mouse&.id, serial_number: row[:mouse_sn] },
            { component_id: comp_floopy_disk&.id, serial_number: row[:floopy_disk_sn] },
            { component_id: comp_processor&.id, serial_number: row[:processor_sn] },
            { component_id: comp_memory&.id, serial_number: row[:memory_sn] },
            { component_id: comp_hardisk&.id, serial_number: row[:hardisk_sn] },
            { component_id: comp_cd_dvd_rom&.id, serial_number: row[:cd_dvd_rom_sn] },
            { component_id: comp_nic&.id, serial_number: row[:nic_sn] },
            { component_id: comp_others&.id, serial_number: row[:others_sn] }
          ])

          data << asset
        end

        Turbo::StreamsChannel.broadcast_append_to(
          "account_#{current_account.id}",
          target: "asset_import_logs",
          partial: "admin/asset_management/assets/turbo_assets_import_logs",
          locals: { state: "importing", error_message: error_message, row_index: nil, tagging_id: nil }
        )

        Asset.import data, recursive: true, batch_size: 1000

        # update counter cache di table user_assets untuk column assets_count
        sql_update_user_assets_count = <<-SQL
          UPDATE user_assets
          SET assets_count = (
            SELECT COUNT(*)
            FROM assets a
            WHERE a.user_asset_id = user_assets.id
          )
        SQL

        ActiveRecord::Base.connection.execute(sql_update_user_assets_count)
      end

      asset_import_queue = AssetImportQueue.find_by(job_id: self.job_id)
      asset_import_queue.update(error_messages: nil, finished_at: Time.now)
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_import_logs",
        partial: "admin/asset_management/assets/turbo_assets_import_logs",
        locals: { state: "success", error_message: nil, row_index: nil, tagging_id: nil, execution_time: (asset_import_queue.finished_at - asset_import_queue.scheduled_at).round(3) }
      )
      if File.exist?(file_path)
        File.delete(file_path)
        puts "File berhasil dihapus: #{file_path}"
      end

    rescue Roo::HeaderRowNotFoundError => e
      error_message = "Header template invalid: #{e}"
      AssetImportQueue.find_by(job_id: self.job_id).update(error_messages: error_message)
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_import_logs",
        partial: "admin/asset_management/assets/turbo_assets_import_logs",
        locals: { state: "error", error_message: error_message, row_index: nil, tagging_id: nil }
      )

    rescue RollbackError => e
      puts "Raise RollbackError => #{e}"
      AssetImportQueue.find_by(job_id: self.job_id).update(error_messages: e)
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_import_logs",
        partial: "admin/asset_management/assets/turbo_assets_import_logs",
        locals: { state: "error", error_message: e, row_index: nil, tagging_id: nil }
      )

    rescue ActiveRecord::RecordNotUnique => e
      duplicate_field = e.message.match(/Key \((.*?)\)=/)[1] rescue "data"
      duplicate_value = e.message.match(/\((.*?)\)=\((.*?)\)/)[2] rescue "unknown"
      error_message = "Dulicate data found: '#{duplicate_field.humanize}' with value '#{duplicate_value}' already exists"
      AssetImportQueue.find_by(job_id: self.job_id).update(error_messages: error_message)
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_import_logs",
        partial: "admin/asset_management/assets/turbo_assets_import_logs",
        locals: { state: "error", error_message: error_message, row_index: nil, tagging_id: nil }
      )

    rescue ActiveRecord::NotNullViolation => e
      logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
      error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
      error_row = data.find { |r| r[error_column.to_sym].nil? }
      error_message = "#{error_column} can't be blank. Row: #{error_row.inspect}"
      AssetImportQueue.find_by(job_id: self.job_id).update(error_messages: error_message)
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_import_logs",
        partial: "admin/asset_management/assets/turbo_assets_import_logs",
        locals: { state: "error", error_message: error_message, row_index: nil, tagging_id: nil }
      )

    rescue => e
      logger.error "#{Current.request_id} - General error during import: #{e.message}"
      AssetImportQueue.find_by(job_id: self.job_id).update(error_messages: "Internal eror: #{e.message}")
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_import_logs",
        partial: "admin/asset_management/assets/turbo_assets_import_logs",
        locals: { state: "error", error_message: "Internal server error. Please contact webmaster", row_index: nil, tagging_id: nil }
      )

    end
  end

  def update_import_status
  end

  private
    def validate_presence_of(value, message)
      if value.nil?
        raise ActiveRecord::Rollback
        message
      end
    end
end

class RollbackError < StandardError; end
