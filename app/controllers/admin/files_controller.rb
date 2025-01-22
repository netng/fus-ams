module Admin
  class FilesController < ApplicationAdminController
    def show
      skip_authorization

      blob = ActiveStorage::Blob.find_signed(params[:id])

      if blob
        headers['Content-Type'] = blob.content_type
        headers['Content-Disposition'] = "inline; filename=\"#{blob.filename}\""
        headers['Cache-Control'] = 'max-age=0, private, must-revalidate'

        # Jangan tetapkan Content-Length untuk menghindari mismatch
        headers.delete('Content-Length')

        stream_file(blob.url)
      else
        render plain: "File not found", status: :not_found
      end
    end

    private

    def stream_file(url)
      require 'open-uri'

      URI.open(url) do |stream|
        while (chunk = stream.read(16.kilobytes))
          response.stream.write(chunk)
        end
      rescue IOError
        logger.error "Streaming interrupted"
      ensure
        response.stream.close
      end
    end
  end
end

