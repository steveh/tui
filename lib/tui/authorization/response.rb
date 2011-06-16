module Tui
  module Authorization
    class Response

      attr_reader :remote_url, :headers

      def initialize(json)
        @remote_url = json.delete(:remote_url)
        @headers = json.delete(:headers)
      end

    end
  end
end