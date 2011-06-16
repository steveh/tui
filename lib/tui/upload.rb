require "digest/md5"
require "mime/types"
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

    def original_filename
      @original_filename ||= File.basename(path)
    end

    def md5sum
      @digest ||= Digest::MD5.file(path)
      @md5sum ||= @digest.hexdigest
    end

    def mime_type
      @mime_type ||= MIME::Types.type_for(path).first.to_s
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

    def as_json
      {
        :original_filename => original_filename,
        :md5sum            => md5sum,
        :size              => size,
        :mime_type         => mime_type,
      }
    end

    private

      def user_agent
        "tui-#{Tui::VERSION}"
      end

  end

end