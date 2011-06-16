require "json/add/rails"

module Tui
  module Authorization
    class Request

      def initialize(upload)
        @upload = upload
      end

      attr_reader :upload

      def perform
        json_request = upload.as_json

        local = Local.new(json_request)

        json_response = local.as_json

        Response.new(json_response)
      end

    end
  end
end