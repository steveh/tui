require "time"
require "base64"
require "openssl"

module Tui
  module Authorization
    class Local

      attr_reader :original_filename, :md5sum, :size, :mime_type

      def initialize(attributes)
        @original_filename = attributes.delete(:original_filename)
        @md5sum = attributes.delete(:md5sum)
        @size = attributes.delete(:size)
        @mime_type = attributes.delete(:mime_type)
      end

      def as_json
        {
          :remote_url => remote_url,
          :headers    => headers,
        }
      end

      private

        def remote_url
          "http://#{bucket}.s3.amazonaws.com#{remote_path}"
        end

        def headers
          http_headers.merge(amz_headers)
        end

        def cache_control
          "public, max-age=#{expires}"
        end

        def current_time_httpdate
          current_time.httpdate
        end

        def expiry_time_httpdate
          expiry_time.httpdate
        end

        def content_md5
          [[md5sum].pack("H*")].pack("m0")
        end

        def content_disposition
          "#{inline_or_attachment}; filename=\"#{original_filename}\""
        end

        def authorization
          "AWS #{aws_access_key_id}:#{signature}"
        end

        def current_time
          @current_time ||= Time.now.utc
        end

        def expiry_time
          current_time + expires
        end

        def expires
          1
        end

        def bucket
          "todo"
        end

        def remote_path
          "/#{id}/#{original_filename}"
        end

        def aws_access_key_id
          "todo"
        end

        def aws_secret_access_key_id
          "todo"
        end

        def id
          @id ||= rand(1000**3).to_s(32)
        end

        def http_headers
          {
            "Cache-Control"       => cache_control,
            "Expires"             => expiry_time_httpdate,
            "Date"                => current_time_httpdate,
            "Content-MD5"         => content_md5,
            "Content-Type"        => mime_type,
            "Content-Disposition" => content_disposition,
            "Authorization"       => authorization,
          }
        end

        def amz_headers
          {
            "x-amz-acl"     => "public-read",
            "x-amz-meta-id" => id.to_s,
          }
        end

        def inline_or_attachment
          "inline"
        end

        def signature
          hmac_digest = OpenSSL::HMAC.digest("sha1", aws_secret_access_key_id, string_to_sign)
          Base64.encode64(hmac_digest).chomp
        end

        def canonical_amz_headers
          amz_headers.sort{ |a, b| a[0] <=> b[0] }.collect{ |(key, value)| "#{key}:#{value}" }
        end

        def canonical_resource
          "/#{bucket}#{remote_path}"
        end

        def string_to_sign
          "PUT\n#{content_md5}\n#{mime_type}\n#{current_time.httpdate}\n#{canonical_amz_headers.join("\n")}\n#{canonical_resource}"
        end

    end
  end
end