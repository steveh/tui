module Tui
  class UploadAuthorization

    def initialize(upload)
      @file = upload.file
    end

    def remote_url
      "http://#{bucket}.s3.amazonaws.com#{remote_path}"
    end

    def headers
      http_headers.merge(amz_headers)
    end

    private

      def path
        @file.path
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
        @content_md5 ||= digest.base64digest
      end

      def content_type
        @content_type ||= MIME::Types.type_for(path).first.to_s
      end

      def content_disposition
        "#{inline_or_attachment}; filename=\"#{download_filename}\""
      end

      def authorization
        "AWS #{aws_access_key_id}:#{signature}"
      end

      def digest
        @digest ||= Digest::MD5.file(path)
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

      def remote_filename
        "todo.jpg"
      end

      def remote_path
        "/#{remote_filename}"
      end

      def download_filename
       "todo.jpg"
      end

      def aws_access_key_id
        "todo"
      end

      def aws_secret_access_key_id
        "todo"
      end

      def tuis_id
        "todo"
      end

      def http_headers
        {
          "Cache-Control"       => cache_control,
          "Expires"             => expiry_time_httpdate,
          "Date"                => current_time_httpdate,
          "Content-MD5"         => content_md5,
          "Content-Type"        => content_type,
          "Content-Disposition" => content_disposition,
          "Authorization"       => authorization,
        }
      end

      def amz_headers
        {
          "x-amz-acl"          => "public-read",
          "x-amz-meta-tuis-id" => tuis_id,
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
        "PUT\n#{content_md5}\n#{content_type}\n#{current_time.httpdate}\n#{canonical_amz_headers.join("\n")}\n#{canonical_resource}"
      end

  end
end