# frozen_string_literal: true

require "base64"
require "json"
require "marcel"
require "openai"
require "pathname"
require "stringio"
require "fileutils"

module AI
  # :reek:MissingSafeMethod { exclude: [ generate! ] }
  # :reek:TooManyMethods
  # :reek:TooManyInstanceVariables
  # :reek:InstanceVariableAssumption
  # :reek:IrresponsibleModule
  class Chat
    # :reek:Attribute
    attr_accessor :messages, :model, :web_search, :previous_response_id, :image_generation, :image_folder, :code_interpreter
    attr_reader :reasoning_effort, :client, :schema

    VALID_REASONING_EFFORTS = [:low, :medium, :high].freeze

    def initialize(api_key: nil, api_key_env_var: "OPENAI_API_KEY")
      api_key ||= ENV.fetch(api_key_env_var)
      @messages = []
      @reasoning_effort = nil
      @model = "gpt-4.1-nano"
      @client = OpenAI::Client.new(api_key: api_key)
      @previous_response_id = nil
      @image_generation = false
      @image_folder = "./images"
    end

    # :reek:TooManyStatements
    # :reek:NilCheck
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

        all_images = []
        all_images << image if image
        all_images.concat(Array(images)) if images

        all_images.each do |img|
          text_and_files_array.push(
            {
              type: "input_image",
              image_url: process_image_input(img)
            }
          )
        end

        all_files = []
        all_files << file if file
        all_files.concat(Array(files)) if files

        all_files.each do |file|
          text_and_files_array.push(process_file_input(file))
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
      add(message, role: "system").last
    end
    
    def user(message, image: nil, images: nil, file: nil, files: nil)
      add(message, role: "user", image: image, images: images, file: file, files: files).last
    end
    
    def assistant(message, response: nil)
      add(message, role: "assistant", response: response).last
    end

    # :reek:NilCheck
    # :reek:TooManyStatements
    def generate!
      response = create_response

      text_response = extract_text_from_response(response)

      image_filenames = extract_and_save_images(response) + extract_and_save_files(response)
      response_usage = response.usage.to_h.slice(:input_tokens, :output_tokens, :total_tokens)

      chat_response = {
        id: response.id,
        model: response.model,
        usage: response_usage,
        total_tokens: response_usage[:total_tokens],
        images: image_filenames
      }

      message = if schema
        if text_response.nil? || text_response.empty?
          raise ArgumentError, "No text content in response to parse as JSON for schema: #{schema.inspect}"
        end
        JSON.parse(text_response, symbolize_names: true)
      else
        text_response
      end

      if image_filenames.empty?
        assistant(message, response: chat_response)
      else
        messages.push(
          {
            role: "assistant",
            content: message,
            images: image_filenames,
            response: chat_response
          }.compact
        )
      end

      self.previous_response_id = chat_response[:id]
      last
    end

    # :reek:NilCheck
    # :reek:TooManyStatements
    def reasoning_effort=(value)
      if value.nil?
        @reasoning_effort = nil
        return
      end

      normalized_value = value.to_sym

      if VALID_REASONING_EFFORTS.include?(normalized_value)
        @reasoning_effort = normalized_value
      else
        valid_values = VALID_REASONING_EFFORTS.map { |valid_value| ":#{valid_value} or \"#{valid_value}\"" }.join(", ")
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

    # Support for Ruby's pp (pretty print)
    # :reek:TooManyStatements
    # :reek:NilCheck
    # :reek:FeatureEnvy
    # :reek:DuplicateMethodCall
    # :reek:UncommunicativeParameterName
    def pretty_print(q)
      q.group(1, "#<#{self.class}", '>') do
        q.breakable
        
        # Show messages with truncation
        q.text "@messages="
        truncated_messages = @messages.map do |msg|
          truncated_msg = msg.dup
          if msg[:content].is_a?(String) && msg[:content].length > 80
            truncated_msg[:content] = msg[:content][0..77] + "..."
          end
          truncated_msg
        end
        q.pp truncated_messages
        
        # Show other instance variables (except sensitive ones)
        skip_vars = [:@messages, :@api_key, :@client]
        instance_variables.sort.each do |var|
          next if skip_vars.include?(var)
          value = instance_variable_get(var)
          unless value.nil?
            q.text ","
            q.breakable
            q.text "#{var}="
            q.pp value
          end
        end
      end
    end

    private

    class InputClassificationError < StandardError; end

    # :reek:FeatureEnvy
    # :reek:ManualDispatch
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

    # :reek:TooManyStatements
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

      previous_response_index = messages.find_index { |message| message.dig(:response, :id) == previous_response_id }

      if previous_response_index
        messages[(previous_response_index + 1)..] || []
      else
        messages
      end
    end

    # :reek:DuplicateMethodCall
    # :reek:FeatureEnvy
    # :reek:ManualDispatch
    # :reek:TooManyStatements
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

    # :reek:DuplicateMethodCall
    # :reek:ManualDispatch
    # :reek:TooManyStatements
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
            file_data: encode_as_data_uri(pdf_data, mime_type)
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
            file_data: encode_as_data_uri(content, mime_type)
          }
        else
          begin
            text_content = content.force_encoding("UTF-8")
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

    # :reek:ManualDispatch
    # :reek:TooManyStatements
    def process_image_input(obj)
      case classify_obj(obj)
      when :url
        obj
      when :file_path
        mime_type = Marcel::MimeType.for(Pathname.new(obj))
        image_data = File.binread(obj)
        encode_as_data_uri(image_data, mime_type)
      when :file_like
        filename = extract_filename(obj)
        file_data = obj.read
        obj.rewind if obj.respond_to?(:rewind)
        mime_type = Marcel::MimeType.for(StringIO.new(file_data), name: filename)
        encode_as_data_uri(file_data, mime_type)
      end
    end

    # :reek:UtilityFunction
    def encode_as_data_uri(data, mime_type)
      "data:#{mime_type};base64,#{Base64.strict_encode64(data)}"
    end

    # :reek:DuplicateMethodCall
    # :reek:UtilityFunction
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
      if image_generation
        tools_list << {type: "image_generation"}
      end
      if code_interpreter
        tools_list << {type: "code_interpreter", container: {type: "auto"}}
      end
      tools_list
    end

    # :reek:UtilityFunction
    # :reek:ManualDispatch
    # :reek:TooManyStatements
    def extract_text_from_response(response)
      output_with_content = response.output.flat_map do |output|
        output.respond_to?(:content) ? output.content : []
      end.compact

      response_output_text_array = output_with_content.select do |content|
        content.is_a?(OpenAI::Models::Responses::ResponseOutputText)
      end

      response_output_text_array.map(&:text).join("\n")
    end

    # :reek:FeatureEnvy
    # :reek:UtilityFunction
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

    # :reek:DuplicateMethodCall
    # :reek:FeatureEnvy
    # :reek:ManualDispatch
    # :reek:TooManyStatements
    def extract_and_save_images(response)
      image_filenames = []

      image_outputs = response.output.select { |output|
        output.respond_to?(:type) && output.type == :image_generation_call
      }

      return image_filenames if image_outputs.empty?

      subfolder_path = create_images_folder(response.id)

      image_outputs.each_with_index do |output, index|
        next unless output.respond_to?(:result) && output.result

        warn_if_file_fails_to_save do
          image_data = Base64.strict_decode64(output.result)

          filename = "#{(index + 1).to_s.rjust(3, "0")}.png"
          file_path = File.join(subfolder_path, filename)

          File.binwrite(file_path, image_data)

          image_filenames << file_path
        end
      end

      image_filenames
    end

    def create_images_folder(response_id)
      # ISO 8601 basic format with centisecond precision
      timestamp = Time.now.strftime("%Y%m%dT%H%M%S%2N")

      subfolder_name = "#{timestamp}_#{response_id}"
      subfolder_path = File.join(image_folder || "./images", subfolder_name)
      FileUtils.mkdir_p(subfolder_path)
      subfolder_path
    end

    def warn_if_file_fails_to_save
      begin
        yield
      rescue => error
        warn "Failed to save image: #{error.message}"
      end
    end

    # :reek:FeatureEnvy
    # :reek:ManualDispatch
    # :reek:NestedIterators
    # :reek:TooManyStatements
    def extract_and_save_files(response)
      filenames = []

      message_outputs = response.output.select do |output|
        output.respond_to?(:type) && output.type == :message
      end

      outputs_with_annotations = message_outputs.map do |message|
        message.content.find do |content|
          content.respond_to?(:annotations) && content.annotations.length.positive?
        end
      end.compact

      return filenames if outputs_with_annotations.empty?

      subfolder_path = create_images_folder(response.id)
      annotations = outputs_with_annotations.map do |output|
        output.annotations.find do |annotation|
          annotation.respond_to?(:filename)
        end
      end.compact

      annotations.each do |annotation|
        container_id = annotation.container_id
        file_id = annotation.file_id
        filename = annotation.filename

        warn_if_file_fails_to_save do
          container_content = client.containers.files.content
          file_content = container_content.retrieve(file_id, container_id: container_id)
          file_path = File.join(subfolder_path, filename)
          File.open(file_path, "wb") do |file|
            file.write(file_content.read)
          end
          filenames << file_path
        end
      end

      filenames
    end
  end
end
