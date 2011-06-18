module Tui
  module Authorization
    class Response

      attr_reader :short_url, :upload_url, :headers

      def initialize(json)
        @short_url = json.delete("short_url")
        @upload_url = json.delete("upload_url")
        @headers = json.delete("headers")
      end

    end
  end
end