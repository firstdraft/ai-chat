require "net/http"
module AI
  module Http
    def send_request(uri, content_type: nil, parameters: nil, method:)
      Net::HTTP.start(uri.host, 443, use_ssl: true) do |http|
        headers = {
          "Authorization" => "Bearer #{@api_key}"
        }
        if content_type
          headers.store("Content-Type", "application/json")
        end
        net_http_method = "Net::HTTP::#{method.downcase.capitalize}"
        client = Kernel.const_get(net_http_method)
        request = client.new(uri, headers)

        if parameters
          request.body = parameters.to_json
        end
        response = http.request(request)

        # Handle proxy server 503 HTML response
        begin
          if content_type
            return JSON.parse(response.body, symbolize_names: true)
          else
            return response.body
          end
        rescue JSON::ParserError, TypeError => e
          raise JSON::ParserError, "Failed to parse response from proxy: #{e.message}"
        end
      end
    end

    def create_deep_struct(value)
      case value
      when Hash
        OpenStruct.new(value.transform_values { |hash_value| send __method__, hash_value })
      when Array
        value.map { |element| send __method__, element }
      else
        value
      end
    end
  end
end
