# frozen_string_literal: true

# All dependencies are now required in the main ai-chat.rb file

module AI
  class Chat
    attr_accessor :messages, :schema, :model, :provider

    PROVIDERS = {
      openai: {
        default_model: "gpt-4o",
        api_endpoint: "https://api.openai.com/v1/chat/completions",
        token_env_vars: ["AI_TOKEN", "OPENAI_TOKEN"]
      },
      gemini: {
        default_model: "gemini-1.5-pro",
        api_endpoint: "https://generativelanguage.googleapis.com/v1/models",
        token_env_vars: ["GEMINI_TOKEN", "GOOGLE_API_KEY"]
      },
      anthropic: {
        default_model: "claude-3-opus-20240229",
        api_endpoint: "https://api.anthropic.com/v1/messages",
        token_env_vars: ["ANTHROPIC_API_KEY"]
      }
    }

    def initialize(api_token: nil, provider: :openai, model: nil)
      @provider = provider.to_sym
      provider_config = PROVIDERS[@provider] || PROVIDERS[:openai]
      
      @api_token = api_token || find_api_token(provider_config[:token_env_vars])
      @messages = []
      @model = model || provider_config[:default_model]
    end

    def find_api_token(env_vars)
      env_vars.each do |var|
        token = ENV.fetch(var, nil)
        return token if token
      end
      nil
    end

    def system(content)
      messages.push({role: "system", content: content})
    end

    def user(content, image: nil, images: nil)
      if content.is_a?(Array)
        processed_content = content.map do |item|
          if item.key?("image") || item.key?(:image)
            image_value = item.fetch("image") { item.fetch(:image) }
            {
              type: "image_url",
              image_url: {
                url: process_image(image_value)
              }
            }
          elsif item.key?("text") || item.key?(:text)
            text_value = item.fetch("text") { item.fetch(:text) }
            {
              type: "text",
              text: text_value
            }
          else
            item
          end
        end

        messages.push(
          {
            role: "user",
            content: processed_content
          }
        )
      elsif image.nil? && images.nil?
        messages.push(
          {
            role: "user",
            content: content
          }
        )
      else
        text_and_images_array = [
          {
            type: "text",
            text: content
          }
        ]

        if images && !images.empty?
          images_array = images.map do |image|
            {
              type: "image_url",
              image_url: {
                url: process_image(image)
              }
            }
          end

          text_and_images_array += images_array
        else
          text_and_images_array.push(
            {
              type: "image_url",
              image_url: {
                url: process_image(image)
              }
            }
          )
        end

        messages.push(
          {
            role: "user",
            content: text_and_images_array
          }
        )
      end
    end

    def assistant(content)
      messages.push({role: "assistant", content: content})
    end

    def assistant!
      request_headers_hash = {
        "Authorization" => "Bearer #{@api_token}",
        "content-type" => "application/json"
      }

      response_format = if schema.nil?
        {
          "type" => "text"
        }
      else
        {
          "type" => "json_schema",
          "json_schema" => JSON.parse(schema)
        }
      end

      request_body_hash = {
        "model" => model,
        "response_format" => response_format,
        "messages" => messages
      }

      request_body_json = JSON.generate(request_body_hash)

      uri = URI("https://api.openai.com/v1/chat/completions")
      raw_response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(uri, request_headers_hash)
        request.body = request_body_json
        http.request(request)
      end

      parsed_response = JSON.parse(raw_response.body)

      content = parsed_response.fetch("choices").at(0).fetch("message").fetch("content")

      messages.push({role: "assistant", content: content})

      schema.nil? ? content : JSON.parse(content)
    end

    def inspect
      "#<#{self.class.name} @messages=#{messages.inspect} @model=#{@model.inspect} @schema=#{@schema.inspect}>"
    end

    private

    # Custom exception class for input classification errors.
    class InputClassificationError < StandardError; end

    def classify_obj(obj)
      if obj.is_a?(String)
        # Attempt to parse as a URL.
        begin
          uri = URI.parse(obj)
          if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
            return :url
          end
        rescue URI::InvalidURIError
          # Not a valid URL; continue to check if it's a file path.
        end

        # Check if the string represents a local file path (must exist on disk).
        if File.exist?(obj)
          :file_path
        else
          raise InputClassificationError,
            "String provided is neither a valid URL (must start with http:// or https://) nor an existing file path on disk. Received value: #{obj.inspect}"
        end
      elsif obj.respond_to?(:read)
        # For non-String objects, check if it behaves like a file.
        :file_like
      else
        raise InputClassificationError,
          "Object provided is neither a String nor file-like (missing :read method). Received value: #{obj.inspect}"
      end
    end

    def process_image(obj)
      case classify_obj(obj)
      when :url
        obj
      when :file_path
        file_path = obj

        mime_type = MIME::Types.type_for(file_path).first.to_s

        image_data = File.binread(file_path)

        base64_string = Base64.strict_encode64(image_data)

        "data:#{mime_type};base64,#{base64_string}"
      when :file_like
        filename = if obj.respond_to?(:path)
          obj.path
        elsif obj.respond_to?(:original_filename)
          obj.original_filename
        else
          "unknown"
        end

        mime_type = MIME::Types.type_for(filename).first.to_s
        mime_type = "image/jpeg" if mime_type.empty?

        image_data = obj.read
        obj.rewind if obj.respond_to?(:rewind)

        base64_string = Base64.strict_encode64(image_data)

        "data:#{mime_type};base64,#{base64_string}"
      end
    end
  end
end
