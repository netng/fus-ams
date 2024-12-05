module ApplicationHelper
  include Pagy::Frontend

  def human_readable_size(file_path)
    if File.exist?(file_path)
      file_size_in_bytes = File.size(file_path)
      (file_size_in_bytes.to_f / 1_048_576).round(2)
    else
      0
    end
  end
end
