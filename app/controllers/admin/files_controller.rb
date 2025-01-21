module Admin
  class FilesController < ApplicationAdminController
    include Rails.application.routes.url_helpers

    def show
      skip_authorization

      blob = ActiveStorage::Blob.find_signed(params[:id])

      if blob
        # Dapatkan URL sementara dari ActiveStorage
        service_url = blob.url

        # Gunakan streaming file dengan `send_file`
        headers['Content-Type'] = blob.content_type
        headers['Content-Disposition'] = 'inline; filename="' + blob.filename.to_s + '"'
        headers['Cache-Control'] = 'max-age=0, private, must-revalidate'

        # Proxy file dari URL MinIO ke pengguna
        stream_file(service_url)
      else
        render plain: "File not found", status: :not_found
      end
    end

    private
      def stream_file(url)
        require 'open-uri'

        # Buka URL sebagai stream
        URI.open(url) do |stream|
          while (chunk = stream.read(16.kilobytes))
            response.stream.write(chunk)
          end
        end
      ensure
        response.stream.close
      end

  end
end
