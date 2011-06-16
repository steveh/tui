require "digest/md5"
require "time"
require "mime/types"
require "base64"
require "openssl"
require "excon"

module Tui

  class Upload

    attr_reader :path
    attr_accessor :authorization

    def initialize(path)
      @path = File.realpath(path)
    end

    def file
      @file ||= File.new(path, "r")
    end

    def size
      @size ||= File.size(path)
    end

    def chunks
      @chunks ||= (size / Excon::Connection::CHUNK_SIZE.to_f).ceil
    end

    def perform(authorization, &block)
      connection = Excon.new(authorization.remote_url)

      headers = {
        "User-Agent" => user_agent,
      }.merge(authorization.headers)

      connection.request_with_uploadprogress(
        :method          => "PUT",
        :body            => file,
        :headers         => headers,
        :expects         => 200,
        :upload_progress => block
      )

      true
    end

    private

      def user_agent
        "tui-#{Tui::VERSION}"
      end

  end

end