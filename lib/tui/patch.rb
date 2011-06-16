module Excon
  class Connection
    
    CHUNK_SIZE = 128 * 1024

    def request_with_uploadprogress(params, &block)
      begin
        # connection has defaults, merge in new params to override
        params = @connection.merge(params)
        params[:headers] = @connection[:headers].merge(params[:headers] || {})
        params[:headers]['Host'] ||= '' << params[:host] << ':' << params[:port]

        # if path is empty or doesn't start with '/', insert one
        unless params[:path][0, 1] == '/'
          params[:path].insert(0, '/')
        end

        if params[:mock]
          for stub, response in Excon.stubs
            # all specified non-headers params match and no headers were specified or all specified headers match
            if [stub.keys - [:headers]].all? {|key| stub[key] == params[key] } &&
              (!stub.has_key?(:headers) || stub[:headers].keys.all? {|key| stub[:headers][key] == params[:headers][key]})
              case response
              when Proc
                return Excon::Response.new(response.call(params))
              else
                return Excon::Response.new(response)
              end
            end
          end
          # if we reach here no stubs matched
          raise(Excon::Errors::StubNotFound.new('no stubs matched ' << params.inspect))
        end

        # start with "METHOD /path"
        request = params[:method].to_s.upcase << ' '
        if @proxy
          request << params[:scheme] << '://' << params[:host] << ':' << params[:port]
        end
        request << params[:path]

        # add query to path, if there is one
        case params[:query]
        when String
          request << '?' << params[:query]
        when Hash
          request << '?'
          for key, values in params[:query]
            if values.nil?
              request << key.to_s << '&'
            else
              for value in [*values]
                request << key.to_s << '=' << CGI.escape(value.to_s) << '&'
              end
            end
          end
          request.chop! # remove trailing '&'
        end

        # finish first line with "HTTP/1.1\r\n"
        request << HTTP_1_1

        # calculate content length and set to handle non-ascii
        unless params[:headers].has_key?('Content-Length')
          params[:headers]['Content-Length'] = case params[:body]
          when File
            params[:body].binmode
            File.size(params[:body])
          when String
            if FORCE_ENC
              params[:body].force_encoding('BINARY')
            end
            params[:body].length
          else
            0
          end
        end

        # add headers to request
        for key, values in params[:headers]
          for value in [*values]
            request << key.to_s << ': ' << value.to_s << CR_NL
          end
        end

        # add additional "\r\n" to indicate end of headers
        request << CR_NL

        # write out the request, sans body
        socket.write(request)
        socket.flush

        # PATCH BEGINS

        bytes_written = 0
        bytes_total = params[:headers]['Content-Length']

        # write out the body
        if params[:body]
          if params[:body].is_a?(String)
            socket.write(params[:body])
          else
            while chunk = params[:body].read(CHUNK_SIZE)
              socket.write(chunk)
              bytes_written += CHUNK_SIZE
              if params[:upload_progress]
                params[:upload_progress].call([bytes_written, bytes_total].min, bytes_total)
              end
            end
          end
        end
        
        # PATCH ENDS

        # read the response
        response = Excon::Response.parse(socket, params, &block)

        if response.headers['Connection'] == 'close'
          reset
        end

        response
      rescue Excon::Errors::StubNotFound => stub_not_found
        raise(stub_not_found)
      rescue => socket_error
        reset
        raise(Excon::Errors::SocketError.new(socket_error))
      end

      if params.has_key?(:expects) && ![*params[:expects]].include?(response.status)
        reset
        raise(Excon::Errors.status_error(params, response))
      else
        response
      end

    rescue => request_error
      if params[:idempotent] && [Excon::Errors::SocketError, Excon::Errors::HTTPStatusError].include?(request_error)
        retries_remaining ||= 4
        retries_remaining -= 1
        if retries_remaining > 0
          if params[:body].respond_to?(:pos=)
            params[:body].pos = 0
          end
          retry
        else
          raise(request_error)
        end
      else
        raise(request_error)
      end
    end

  end
end