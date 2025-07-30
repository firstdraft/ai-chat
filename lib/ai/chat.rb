# frozen_string_literal: true

require "base64"
require "mime-types"
require "openai"

require_relative "response"

module AI
  # Main namespace.
  class Chat
    def self.loader(registry = Zeitwerk::Registry)
      @loader ||= registry.loaders.each.find { |loader| loader.tag == "ai-chat" }
    end

    attr_accessor :messages, :schema, :model, :web_search
    attr_reader :reasoning_effort, :client

    VALID_REASONING_EFFORTS = [:low, :medium, :high].freeze
    
    def initialize(api_key: nil, api_key_env_var: "OPENAI_API_KEY")
      @api_key = api_key || ENV.fetch(api_key_env_var)
      @messages = []
      @reasoning_effort = nil
      @model = "gpt-4.1-nano"
      @client = OpenAI::Client.new(api_key: @api_key)
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

        if images && !images.empty?
          images_array = images.map do |image|
            {
              type: "input_image",
              image_url: process_file(image)
            }
          end

          text_and_files_array += images_array
        elsif image
          text_and_files_array.push(
            {
              type: "input_image",
              image_url: process_file(image)
            }
          )
        elsif files && !files.empty?
          files_array = files.map do |file|
            {
              type: "input_file",
              filename: "test",
              file_data: process_file(file)
            }
          end

          text_and_files_array += files_array
        else
          text_and_files_array.push(
            {
              type: "input_file",
              filename: "test",
              file_data: process_file(file)
            }
          )

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

      if web_search
        message = response.output.last.content.first.text
        chat_response = Response.new(response)
        assistant(message, response: chat_response)
      elsif schema
        # filtering out refusals...
        json_response = response.output.flat_map { _1.content }.select { _1.is_a?(OpenAI::Models::Responses::ResponseOutputText)}.first.text
        chat_response = Response.new(response)
        message = JSON.parse(json_response, symbolize_names: true)
        assistant(message, response: chat_response)
      else
        message = response.output.last.content.first.text
        chat_response = Response.new(response)
        assistant(message, response: chat_response)
      end

      message
    end

    def pick_up_from(response_id)
      response = client.responses.retrieve(response_id)
      chat_response = Response.new(response)
      message = response.output.flat_map { _1.content }.select { _1.is_a?(OpenAI::Models::Responses::ResponseOutputText)}.first.text
      assistant(message, response: chat_response)
      message
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
  
    def schema=(value)
      if value.is_a?(String)
        @schema = JSON.parse(value, symbolize_names: true)
        unless @schema.key?(:format) || @schema.key?("format")
          @schema = { format: @schema }
        end
      elsif value.is_a?(Hash)
        if value.key?(:format) || value.key?("format")
          @schema = value
        else
          @schema = { format: value }
        end
      else
        raise ArgumentError, "Invalid schema value: '#{value}'. Must be a String containing JSON or a Hash."
      end
    end

    def last
      messages.last
    end

    def last_response
      last[:response]
    end

    def last_response_id
      last_response&.id
    end

    def inspect
      "#<#{self.class.name} @messages=#{messages.inspect} @model=#{@model.inspect} @schema=#{@schema.inspect} @reasoning_effort=#{@reasoning_effort.inspect}>"
    end

    def to_hash
      hash = { "#{self.class.name}" => {} }
      
      # Define which instance variables to skip
      skip_vars = [:@api_key, :@client]
      
      instance_variables.sort.each do |var|
        next if skip_vars.include?(var)
        
        value = instance_variable_get(var)
        
        # Special handling for @messages to truncate content
        if var == :@messages
          value = value.map do |msg|
            truncated_msg = msg.dup
            if msg[:content].is_a?(String) && msg[:content].length > 80
              truncated_msg[:content] = msg[:content][0..77] + "..."
            end
            truncated_msg
          end
        end
        
        # Skip nil values for cleaner output
        hash["#{self.class.name}"][var.to_s] = value unless value.nil?
      end
      
      hash
    end

    private

    # Custom exception class for input classification errors.
    class InputClassificationError < StandardError; end

    def create_response
      parameters = {
        model: model,
        input: strip_responses(messages),
        tools: tools,
        text: schema,
        reasoning: {
          effort: reasoning_effort
        }.compact
      }.compact
      parameters = parameters.delete_if { |k, v| v.empty? }
      client.responses.create(**parameters)
    end

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

    def process_file(obj)
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

        file_data = obj.read
        obj.rewind if obj.respond_to?(:rewind)

        base64_string = Base64.strict_encode64(file_data)

        "data:#{mime_type};base64,#{base64_string}"
      end
    end

    def strip_responses(messages)
      messages.each do |message|
        message.delete(:response) if message.key?(:response)
        message[:content] = JSON.generate(message[:content]) if message[:content].is_a?(Hash)
      end
    end

    def tools
      tools_list = []
      if web_search
        tools_list << { type: "web_search_preview" } 
      end
    end

    def extract_message(response)
      response.output.flat_map { _1.content }.select { _1.is_a?(OpenAI::Models::Responses::ResponseOutputText)}.first.text
    end
  end
end
