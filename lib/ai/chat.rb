# frozen_string_literal: true

# All dependencies are now required in the main ai-chat.rb file

module AI
  class Chat
    attr_accessor :messages, :schema, :model
    attr_reader :reasoning_effort, :reasoning_output

    VALID_REASONING_EFFORTS = [:low, :medium, :high].freeze

    def initialize(api_key: nil, api_key_env_var: "OPENAI_API_KEY")
      @api_key = api_key || ENV.fetch(api_key_env_var)
      @messages = []
      @model = "gpt-4.1-nano"
      @reasoning_effort = nil
    end

    def reasoning_effort=(value)
      if value.nil?
        @reasoning_effort = nil
      else
        # Convert string to symbol if needed
        symbol_value = value.is_a?(String) ? value.to_sym : value

        if VALID_REASONING_EFFORTS.include?(symbol_value)
          @reasoning_effort = symbol_value
        else
          valid_values = VALID_REASONING_EFFORTS.map { |v| ":#{v} or \"#{v}\"" }.join(", ")
          raise ArgumentError, "Invalid reasoning_effort value: '#{value}'. Must be one of: #{valid_values}"
        end
      end
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
        "Authorization" => "Bearer #{@api_key}",
        "content-type" => "application/json"
      }

      request_body_hash = {
        "model" => model,
        "input" => messages
      }

      # Always add reasoning with summary=auto, and add effort if specified
      reasoning_params = { "summary" => "auto" }
      reasoning_params["effort"] = @reasoning_effort.to_s unless @reasoning_effort.nil?
      request_body_hash["reasoning"] = reasoning_params

      # Handle structured output (JSON schema)
      if !schema.nil?
        # Parse the schema and use it with Structured Output (json_schema)
        schema_obj = JSON.parse(schema)

        # Extract schema name from the parsed schema, or use a default
        schema_name = schema_obj["name"] || "output_object"

        # Responses API uses proper Structured Output with schema
        request_body_hash["text"] = {
          "format" => {
            "type" => "json_schema",
            "schema" => schema_obj["schema"] || schema_obj,
            "name" => schema_name,
            "strict" => true
          }
        }
      end

      request_body_json = JSON.generate(request_body_hash)

      uri = URI("https://api.openai.com/v1/responses")
      raw_response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(uri, request_headers_hash)
        request.body = request_body_json
        http.request(request)
      end

      # Handle empty responses or HTTP errors
      if raw_response.code.to_i >= 400
        raise "HTTP Error #{raw_response.code}: #{raw_response.message}\n#{raw_response.body}"
      end

      if raw_response.body.nil? || raw_response.body.empty?
        raise "Empty response received from OpenAI API"
      end

      parsed_response = JSON.parse(raw_response.body)

      # Check for API errors
      if parsed_response.key?("error") && parsed_response["error"].is_a?(Hash)
        error_message = parsed_response["error"]["message"] || parsed_response["error"].inspect
        raise "OpenAI API Error: #{error_message}"
      end

      # Extract the text content and reasoning from the response
      content = ""
      reasoning_data = nil

      # Parse response according to the documented structure
      if parsed_response.key?("output") && parsed_response["output"].is_a?(Array) && !parsed_response["output"].empty?
        # Extract reasoning data if available
        reasoning_item = parsed_response["output"].find { |item| item["type"] == "reasoning" }
        if reasoning_item && reasoning_item.key?("summary")
          reasoning_data = reasoning_item["summary"]
        end
        
        # Find the message output item, which may not be the first item when reasoning is used
        message_output_item = parsed_response["output"].find { |item| item["type"] == "message" }

        if message_output_item&.key?("content")
          content_items = message_output_item["content"]
          output_text_item = content_items.find { |item| item["type"] == "output_text" }

          content = output_text_item&.key?("text") ? output_text_item["text"] : ""
        end
      end

      # If no content is found, throw an error
      if content.empty?
        raise "Failed to extract content from response: #{parsed_response.inspect}"
      end

      # Store the assistant message with reasoning data if available
      message_data = {role: "assistant", content: content}
      message_data[:reasoning] = reasoning_data if reasoning_data
      messages.push(message_data)

      schema.nil? ? content : JSON.parse(content)
    end

    # Get reasoning data for the last assistant message or a specific index
    def reasoning(index = nil)
      if index.nil?
        # Get reasoning from the last assistant message
        messages.reverse.find { |msg| msg[:role] == "assistant" && msg.key?(:reasoning) }&.fetch(:reasoning)
      else
        # Get reasoning from a specific message index
        messages[index][:reasoning] if messages[index] && messages[index][:role] == "assistant" && messages[index].key?(:reasoning)
      end
    end

    def inspect
      "#<#{self.class.name} @messages=#{messages.inspect} @model=#{@model.inspect} @schema=#{@schema.inspect} @reasoning_effort=#{@reasoning_effort.inspect}>"
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
