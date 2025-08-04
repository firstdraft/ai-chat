# frozen_string_literal: true

require "base64"
require "json"
require "marcel"
require "openai"
require "pathname"
require "stringio"

require_relative "response"

module AI
  # Main namespace.
  class Chat
    attr_accessor :messages, :model, :web_search, :previous_response_id
    attr_reader :reasoning_effort, :client, :schema

    VALID_REASONING_EFFORTS = [:low, :medium, :high].freeze

    def initialize(api_key: nil, api_key_env_var: "OPENAI_API_KEY")
      @api_key = api_key || ENV.fetch(api_key_env_var)
      @messages = []
      @reasoning_effort = nil
      @model = "gpt-4.1-nano"
      @client = OpenAI::Client.new(api_key: @api_key)
      @previous_response_id = nil
    end

    def add(content, role: "user", response: nil, image: nil, images: nil, file: nil, files: nil)
      if image.nil? && images.nil? && file.nil? && files.nil?
        messages.push(
          {
            role: role,
            content: content,
            response: response
          }.compact
        )

      else
        text_and_files_array = [
          {
            type: "input_text",
            text: content
          }
        ]

        # Combine singular and plural image parameters
        all_images = []
        all_images << image if image
        all_images.concat(Array(images)) if images

        # Add all images to the content array
        all_images.each do |img|
          text_and_files_array.push(
            {
              type: "input_image",
              image_url: process_image_input(img)
            }
          )
        end

        # Combine singular and plural file parameters
        all_files = []
        all_files << file if file
        all_files.concat(Array(files)) if files

        # Add all files to the content array
        all_files.each do |f|
          text_and_files_array.push(process_file_input(f))
        end

        messages.push(
          {
            role: role,
            content: text_and_files_array
          }
        )
      end
    end

    def system(message)
      add(message, role: "system")
    end

    def user(message, image: nil, images: nil, file: nil, files: nil)
      add(message, role: "user", image: image, images: images, file: file, files: files)
    end

    def assistant(message, response: nil)
      add(message, role: "assistant", response: response)
    end

    def generate!
      response = create_response

      chat_response = Response.new(response)

      text_response = extract_text_from_response(response)

      message = if schema
        if text_response.nil? || text_response.empty?
          raise ArgumentError, "No text content in response to parse as JSON for schema: #{schema.inspect}"
        end
        JSON.parse(text_response, symbolize_names: true)
      else
        text_response
      end

      assistant(message, response: chat_response)

      self.previous_response_id = response.id

      message
    end

    def reasoning_effort=(value)
      if value.nil?
        @reasoning_effort = nil
        return
      end

      normalized_value = value.to_sym

      if VALID_REASONING_EFFORTS.include?(normalized_value)
        @reasoning_effort = normalized_value
      else
        valid_values = VALID_REASONING_EFFORTS.map { |v| ":#{v} or \"#{v}\"" }.join(", ")
        raise ArgumentError, "Invalid reasoning_effort value: '#{value}'. Must be one of: #{valid_values}"
      end
    end

    def schema=(value)
      if value.is_a?(String)
        parsed = JSON.parse(value, symbolize_names: true)
        @schema = wrap_schema_if_needed(parsed)
      elsif value.is_a?(Hash)
        @schema = wrap_schema_if_needed(value)
      else
        raise ArgumentError, "Invalid schema value: '#{value}'. Must be a String containing JSON or a Hash."
      end
    end

    def last
      messages.last
    end

    def inspect
      "#<#{self.class.name} @messages=#{messages.inspect} @model=#{@model.inspect} @schema=#{@schema.inspect} @reasoning_effort=#{@reasoning_effort.inspect}>"
    end

    private

    class InputClassificationError < StandardError; end

    def extract_filename(obj)
      if obj.respond_to?(:original_filename)
        obj.original_filename
      elsif obj.respond_to?(:path)
        File.basename(obj.path)
      else
        raise InputClassificationError,
          "Unable to determine filename from file object. File objects must respond to :original_filename or :path"
      end
    end

    def create_response
      parameters = {
        model: model
      }

      parameters[:tools] = tools unless tools.empty?
      parameters[:text] = schema if schema
      parameters[:reasoning] = {effort: reasoning_effort} if reasoning_effort
      parameters[:previous_response_id] = previous_response_id if previous_response_id

      messages_to_send = prepare_messages_for_api
      parameters[:input] = strip_responses(messages_to_send) unless messages_to_send.empty?

      client.responses.create(**parameters)
    end

    def prepare_messages_for_api
      return messages unless previous_response_id

      previous_response_index = messages.find_index { |m| m[:response]&.id == previous_response_id }

      if previous_response_index
        # Only send messages after the previous response
        messages[(previous_response_index + 1)..] || []
      else
        messages
      end
    end

    def classify_obj(obj)
      if obj.is_a?(String)
        begin
          uri = URI.parse(obj)
          if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
            return :url
          end
        rescue URI::InvalidURIError
        end

        if File.exist?(obj)
          :file_path
        else
          raise InputClassificationError,
            "String provided is neither a valid URL (must start with http:// or https://) nor an existing file path on disk. Received value: #{obj.inspect}"
        end
      elsif obj.respond_to?(:read)
        :file_like
      else
        raise InputClassificationError,
          "Object provided is neither a String nor file-like (missing :read method). Received value: #{obj.inspect}"
      end
    end

    def process_file_input(obj)
      case classify_obj(obj)
      when :url
        {
          type: "input_file",
          file_url: obj
        }
      when :file_path
        mime_type = Marcel::MimeType.for(Pathname.new(obj))

        if mime_type == "application/pdf"
          pdf_data = File.binread(obj)
          {
            type: "input_file",
            filename: File.basename(obj),
            file_data: "data:application/pdf;base64,#{Base64.strict_encode64(pdf_data)}"
          }
        else
          begin
            content = File.read(obj, encoding: "UTF-8")
            # Verify the content can be encoded as JSON (will raise if not)
            JSON.generate({text: content})
            {
              type: "input_text",
              text: content
            }
          rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError, JSON::GeneratorError
            raise InputClassificationError,
              "Unable to read #{File.basename(obj)} as text. Only PDF and text files are supported."
          end
        end
      when :file_like
        filename = extract_filename(obj)

        content = obj.read
        obj.rewind if obj.respond_to?(:rewind)

        mime_type = Marcel::MimeType.for(StringIO.new(content), name: filename)

        if mime_type == "application/pdf"
          {
            type: "input_file",
            filename: filename,
            file_data: "data:application/pdf;base64,#{Base64.strict_encode64(content)}"
          }
        else
          begin
            text_content = content.force_encoding("UTF-8")
            # Verify the content can be encoded as JSON
            JSON.generate({text: text_content})
            {
              type: "input_text",
              text: text_content
            }
          rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError, JSON::GeneratorError
            raise InputClassificationError,
              "Unable to read #{filename} as text. Only PDF and text files are supported."
          end
        end
      end
    end

    def process_image_input(obj)
      case classify_obj(obj)
      when :url
        obj
      when :file_path
        file_path = obj

        mime_type = Marcel::MimeType.for(Pathname.new(file_path))

        image_data = File.binread(file_path)

        base64_string = Base64.strict_encode64(image_data)

        "data:#{mime_type};base64,#{base64_string}"
      when :file_like
        filename = extract_filename(obj)

        file_data = obj.read
        obj.rewind if obj.respond_to?(:rewind)

        mime_type = Marcel::MimeType.for(StringIO.new(file_data), name: filename)

        base64_string = Base64.strict_encode64(file_data)

        "data:#{mime_type};base64,#{base64_string}"
      end
    end

    def strip_responses(messages)
      messages.map do |message|
        stripped = message.dup
        stripped.delete(:response)
        stripped[:content] = JSON.generate(stripped[:content]) if stripped[:content].is_a?(Hash)
        stripped
      end
    end

    def tools
      tools_list = []
      if web_search
        tools_list << {type: "web_search_preview"}
      end
      tools_list
    end

    def extract_text_from_response(response)
      response.output.flat_map { |output|
        # Only try to access content if the output has that method
        output.respond_to?(:content) ? output.content : []
      }.compact.find { |content|
        content.is_a?(OpenAI::Models::Responses::ResponseOutputText)
      }&.text
    end

    def wrap_schema_if_needed(schema)
      if schema.key?(:format) || schema.key?("format")
        schema
      elsif (schema.key?(:name) || schema.key?("name")) &&
          (schema.key?(:schema) || schema.key?("schema")) &&
          (schema.key?(:strict) || schema.key?("strict"))
        {
          format: schema.merge(type: :json_schema)
        }
      else
        {
          format: {
            type: :json_schema,
            name: "response",
            schema: schema,
            strict: true
          }
        }
      end
    end
  end
end
