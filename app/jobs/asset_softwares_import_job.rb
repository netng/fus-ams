class AssetSoftwaresImportJob < ApplicationJob
  queue_as :default

  def perform(current_account, file_signed_id)
    puts "processing import job id: #{self.job_id}"

    blob = ActiveStorage::Blob.find_signed(file_signed_id)
    puts blob.inspect



    file_path = Rails.root.join("tmp", blob.filename.to_s)
    File.open(file_path, "wb") do |file|
      file.write(blob.download)
    end

    error_message = nil
    data = []

    xlsx = Roo::Spreadsheet.open(file_path.to_s)

    sheet = xlsx.sheet(0)

    asset_softwares_attributes_headers = {
      tagging_id: "Tagging id *",
      software_id_1: "Software id 1",
      software_id_2: "Software id 2",
      software_id_3: "Software id 3",
      software_id_4: "Software id 4",
      software_id_5: "Software id 5",
      software_id_6: "Software id 6",
      software_id_7: "Software id 7",
      software_id_8: "Software id 8",
      software_id_9: "Software id 9",
      software_id_10: "Software id 10",
      license_number_1: "License number 1",
      license_number_2: "License number 2",
      license_number_3: "License number 3",
      license_number_4: "License number 4",
      license_number_5: "License number 5",
      license_number_6: "License number 6",
      license_number_7: "License number 7",
      license_number_8: "License number 8",
      license_number_9: "License number 9",
      license_number_10: "License number 10"
    }

    begin
      ActiveRecord::Base.transaction do
        tagging_ids = []

        sheet.parse(asset_softwares_attributes_headers).each_with_index do |row, index|
          index += 1

          Turbo::StreamsChannel.broadcast_append_to(
            "account_#{current_account.id}",
            target: "asset_softwares_import_logs",
            partial: "admin/asset_management/assets/turbo_asset_softwares_import_logs",
            locals: { state: "preparing", error_message: nil, row_index: index + 1, tagging_id: row[:tagging_id] }
          )

          asset = Asset.find_by_tagging_id(row[:tagging_id]&.strip&.upcase)
          software1 = Software.find_by(id_software: row[:software_id_1]) if row[:software_id_1].present?
          software2 = Software.find_by(id_software: row[:software_id_2]) if row[:software_id_2].present?
          software3 = Software.find_by(id_software: row[:software_id_3]) if row[:software_id_3].present?
          software4 = Software.find_by(id_software: row[:software_id_4]) if row[:software_id_4].present?
          software5 = Software.find_by(id_software: row[:software_id_5]) if row[:software_id_5].present?
          software6 = Software.find_by(id_software: row[:software_id_6]) if row[:software_id_6].present?
          software7 = Software.find_by(id_software: row[:software_id_7]) if row[:software_id_7].present?
          software8 = Software.find_by(id_software: row[:software_id_8]) if row[:software_id_8].present?
          software9 = Software.find_by(id_software: row[:software_id_9]) if row[:software_id_9].present?
          software10 = Software.find_by(id_software: row[:software_id_10]) if row[:software_id_10].present?

          if tagging_ids.include?(row[:tagging_id])
            error_message = "Duplicate entry! Tagging id : #{row[:tagging_id]}'"
            raise RollbackError, error_message
          end

          if row[:tagging_id].nil?
            error_message= "Tagging id must exists at row #{index + 1}"
            raise RollbackError, error_message
          end

          if asset.blank?
            error_message = "Asset with 'Tagging id : #{row[:tagging_id]}' is not found"
            raise RollbackError, error_message
          end

          if row[:software_id_1].present? && validate_software(software1, row[:software_id_1], row[:tagging_id])
            asset_software1 = { asset_id: asset.id, software_id: software1&.id, license: row[:license_number_1], sequence_number: 1 }
            data << asset_software1
          end

          if row[:software_id_2].present? && validate_software(software2, row[:software_id_2], row[:tagging_id])
            asset_software2 = { asset_id: asset.id, software_id: software2&.id, license: row[:license_number_2], sequence_number: 2 }
            data << asset_software2
          end

          if row[:software_id_3].present? && validate_software(software3, row[:software_id_3], row[:tagging_id])
            asset_software3 = { asset_id: asset.id, software_id: software3&.id, license: row[:license_number_3], sequence_number: 3 }
            data << asset_software3
          end

          if row[:software_id_4].present? && validate_software(software4, row[:software_id_4], row[:tagging_id])
            asset_software4 = { asset_id: asset.id, software_id: software4&.id, license: row[:license_number_4], sequence_number: 4 }
            data << asset_software4
          end

          if row[:software_id_5].present? && validate_software(software5, row[:software_id_5], row[:tagging_id])
            asset_software5 = { asset_id: asset.id, software_id: software5&.id, license: row[:license_number_5], sequence_number: 5 }
            data << asset_software5
          end

          if row[:software_id_6].present? && validate_software(software6, row[:software_id_6], row[:tagging_id])
            asset_software6 = { asset_id: asset.id, software_id: software6&.id, license: row[:license_number_6], sequence_number: 6 }
            data << asset_software6
          end

          if row[:software_id_7].present? && validate_software(software7, row[:software_id_7], row[:tagging_id])
            asset_software7 = { asset_id: asset.id, software_id: software7&.id, license: row[:license_number_7], sequence_number: 7 }
            data << asset_software7
          end

          if row[:software_id_8].present? && validate_software(software8, row[:software_id_8], row[:tagging_id])
            asset_software8 = { asset_id: asset.id, software_id: software8&.id, license: row[:license_number_8], sequence_number: 8 }
            data << asset_software8
          end

          if row[:software_id_9].present? && validate_software(software9, row[:software_id_9], row[:tagging_id])
            asset_software9 = { asset_id: asset.id, software_id: software9&.id, license: row[:license_number_9], sequence_number: 9 }
            data << asset_software9
          end

          if row[:software_id_10].present? && validate_software(software10, row[:software_id_10], row[:tagging_id])
            asset_software10 = { asset_id: asset.id, software_id: software10&.id, license: row[:license_number_10], sequence_number: 10 }
            data << asset_software10
          end

          tagging_ids << row[:tagging_id]
        end

        puts "data: #{data.inspect}"


        Turbo::StreamsChannel.broadcast_append_to(
          "account_#{current_account.id}",
          target: "asset_softwares_import_logs",
          partial: "admin/asset_management/assets/turbo_asset_softwares_import_logs",
          locals: { state: "importing", error_message: error_message, row_index: nil, tagging_id: nil }
        )

        AssetSoftware.import data, batch_size: 1000, on_duplicate_key_update: {
          conflict_target: [ :asset_id, :software_id ], columns: [ :software_id, :license ]
        }
      end

      asset_softwares_import_queue = AssetImportQueue.find_by(job_id: self.job_id)
      asset_softwares_import_queue.update(error_messages: nil, finished_at: Time.now)


      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_softwares_import_logs",
        partial: "admin/asset_management/assets/turbo_asset_softwares_import_logs",
        locals: { state: "success", error_message: nil, row_index: nil, tagging_id: nil, execution_time: (asset_softwares_import_queue.finished_at - asset_softwares_import_queue.scheduled_at).round(3) }
      )

    rescue Roo::HeaderRowNotFoundError => e
      error_message = "Header template invalid: #{e}"
      AssetImportQueue.find_by(job_id: self.job_id).update(error_messages: error_message)
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_softwares_import_logs",
        partial: "admin/asset_management/assets/turbo_asset_softwares_import_logs",
        locals: { state: "error", error_message: error_message, row_index: nil, tagging_id: nil }
      )

    rescue RollbackError => e
      puts "Raise RollbackError => #{e}"
      AssetImportQueue.find_by(job_id: self.job_id).update(error_messages: e)
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_softwares_import_logs",
        partial: "admin/asset_management/assets/turbo_asset_softwares_import_logs",
        locals: { state: "error", error_message: e, row_index: nil, tagging_id: nil }
      )

    rescue ActiveRecord::NotNullViolation => e
      logger.error "#{Current.request_id} - NotNullViolation error: #{e.message}"
      error_column = e.message.match(/column "(.*?)"/)[1] # Menangkap nama kolom yang menyebabkan error
      error_row = data.find { |r| r[error_column.to_sym].nil? }
      error_message = "#{error_column} can't be blank. Row: #{error_row.inspect}"
      AssetImportQueue.find_by(job_id: self.job_id).update(error_messages: error_message)
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_softwares_import_logs",
        partial: "admin/asset_management/assets/turbo_asset_softwares_import_logs",
        locals: { state: "error", error_message: error_message, row_index: nil, tagging_id: nil }
      )

    rescue => e
      logger.error "#{Current.request_id} - General error during import: #{e.message}"
      AssetImportQueue.find_by(job_id: self.job_id).update(error_messages: "Internal eror: #{e.message}")
      Turbo::StreamsChannel.broadcast_append_to(
        "account_#{current_account.id}",
        target: "asset_softwares_import_logs",
        partial: "admin/asset_management/assets/turbo_asset_softwares_import_logs",
        locals: { state: "error", error_message: "Internal server error. Please contact webmaster", row_index: nil, tagging_id: nil }
      )
    ensure
      if File.exist?(file_path)
        File.delete(file_path)
        puts "File berhasil dihapus: #{file_path}"
        blob.purge_later
      end



    end
  end

  private
    def validate_software(record, row, tagging_id)
      if record.blank?
        raise RollbackError, "Tagging id: #{tagging_id} - Software with id `#{row}` is not found"
      else
        true
      end
    end
end

class RollbackError < StandardError; end
