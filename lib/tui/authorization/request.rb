require "json/add/rails"
require "base64"

module Tui
  module Authorization
    class Request

      def initialize(upload)
        @upload = upload
      end

      attr_reader :upload

      def perform
        json_request = upload.as_json.to_json

        connection = Excon.new("http://#{Tui::Config.host}/files")

        login = Base64.urlsafe_encode64("#{Tui::Config.username}:#{Tui::Config.password}")

        headers = {
          "Authorization" => "Basic #{login}",
          "Accept"        => "application/json",
          "Content-Type"  => "application/json",
        }

        response = connection.request({
          :method          => "POST",
          :headers         => headers,
          :expects         => 200,
          :body            => json_request,
        })

        json_response = JSON.parse(response.body)

        Response.new(json_response)
      end

    end
  end
end