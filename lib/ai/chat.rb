# frozen_string_literal: true

require "base64"
require "json"
require "marcel"
require "openai"
require "ostruct"
require "pathname"
require "stringio"
require "fileutils"
require "tty-spinner"
require "timeout"

require_relative "http"
include AI::Http

module AI
  # :reek:MissingSafeMethod { exclude: [ generate! ] }
  # :reek:TooManyMethods
  # :reek:TooManyInstanceVariables
  # :reek:InstanceVariableAssumption
  # :reek:IrresponsibleModule
  class Chat
    # :reek:Attribute
    attr_accessor :background, :code_interpreter, :conversation_id, :image_generation, :image_folder, :messages, :model, :proxy, :previous_response_id, :web_search
    attr_reader :reasoning_effort, :client, :schema, :schema_file

    VALID_REASONING_EFFORTS = [:low, :medium, :high].freeze
    PROXY_URL = "https://prepend.me/".freeze

    def initialize(api_key: nil, api_key_env_var: "OPENAI_API_KEY")
      @api_key = api_key || ENV.fetch(api_key_env_var)
      @messages = []
      @reasoning_effort = nil
      @model = "gpt-4.1-nano"
      @client = OpenAI::Client.new(api_key: @api_key)
      @previous_response_id = nil
      @proxy = false
      @image_generation = false
      @image_folder = "./images"
    end

    def self.generate_schema!(description, location: "schema.json", api_key: nil, api_key_env_var: "OPENAI_API_KEY", proxy: false)
      api_key ||= ENV.fetch(api_key_env_var)
      prompt_path = File.expand_path("../prompts/schema_generator.md", __dir__)
      system_prompt = File.open(prompt_path).read

      json = if proxy
        uri = URI(PROXY_URL + "api.openai.com/v1/responses")
        parameters = {
          model: "o4-mini",
          input: [
            {role: :system, content: system_prompt},
            {role: :user, content: description},
          ],
          text: {format: {type: "json_object"}},
          reasoning: {effort: "high"}
        }

        send_request(uri, content_type: "json", parameters: parameters, method: "post")
      else
        client = OpenAI::Client.new(api_key: api_key)
        response = client.responses.create(
          model: "o4-mini",
          input: [
            {role: :system, content: system_prompt},
            {role: :user, content: description}
          ],
          text: {format: {type: "json_object"}},
          reasoning: {effort: "high"}
        )

        output_text = response.output_text
        JSON.parse(output_text)
      end
      content = JSON.pretty_generate(json)
      if location
        path = Pathname.new(location)
        FileUtils.mkdir_p(path.dirname) if path.dirname != "."
        File.open(location, "wb") do |file|
          file.write(content)
        end
      end
      content
    end

    # :reek:TooManyStatements
    # :reek:NilCheck
    def add(content, role: "user", response: nil, status: nil, image: nil, images: nil, file: nil, files: nil)
      if image.nil? && images.nil? && file.nil? && files.nil?
        message = {
          role: role,
          content: content,
          response: response
        }
        message[:content] = content if content
        message[:status] = status if status
        messages.push(message)
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
            content: text_and_files_array,
            status: status
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

    def assistant(message, response: nil, status: nil)
      add(message, role: "assistant", response: response, status: status)
    end

    # :reek:NilCheck
    # :reek:TooManyStatements
    def generate!
      validate_api_key
      response = create_response
      parse_response(response)

      self.previous_response_id = last.dig(:response, :id) unless (conversation_id && !background)
      last
    end

    # :reek:BooleanParameter
    # :reek:ControlParameter
    # :reek:DuplicateMethodCall
    # :reek:TooManyStatements
    def get_response(wait: false, timeout: 600)
      response = if wait
        wait_for_response(timeout)
      else
        retrieve_response(previous_response_id)
      end
      parse_response(response)
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

    def schema_file=(path)
      @schema_file = path
      content = File.open(path).read
      self.schema = content
    end

    def last
      messages.last
    end

    def items(order: :asc)
      raise "No conversation_id set. Call generate! first to create a conversation." unless conversation_id

      if proxy
        uri = URI(PROXY_URL + "api.openai.com/v1/conversations/#{conversation_id}/items?order=#{order.to_s}")
        response_hash = send_request(uri, content_type: "json", method: "get")

        if response_hash.key?(:data)
          response_hash.dig(:data).map do |hash|
            # Transform values to allow expected symbols that non-proxied request returns 

            hash.transform_values! do |value|
              if hash.key(value) == :type
                value.to_sym
              else
                value
              end
            end
          end
          response_hash
        end
        # Convert to Struct to allow same interface as non-proxied request
        create_deep_struct(response_hash)
      else
        client.conversations.items.list(conversation_id, order: order)
      end
    end

    def verbose
      page = items

      box_width = 78
      inner_width = box_width - 4

      puts
      puts "┌#{"─" * (box_width - 2)}┐"
      puts "│ Conversation: #{conversation_id.ljust(inner_width - 14)} │"
      puts "│ Items: #{page.data.length.to_s.ljust(inner_width - 7)} │"
      puts "└#{"─" * (box_width - 2)}┘"
      puts

      ap page.data, limit: 10, indent: 2
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
      q.group(1, "#<#{self.class}", ">") do
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
    class WrongAPITokenUsedError < StandardError; end

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

    def create_conversation
      self.conversation_id = if proxy
        uri = URI(PROXY_URL + "api.openai.com/v1/conversations")
        response = send_request(uri, content_type: "json", method: "post")
        response.dig(:id)
      else
        conversation = client.conversations.create
        conversation.id
      end
    end

    # :reek:TooManyStatements
    def create_response
      parameters = {
        model: model
      }

      parameters[:background] = background if background
      parameters[:tools] = tools unless tools.empty?
      parameters[:text] = schema if schema
      parameters[:reasoning] = {effort: reasoning_effort} if reasoning_effort

      if previous_response_id && conversation_id
        warn "Both conversation_id and previous_response_id are set. Using previous_response_id for forking. Only set one."
        parameters[:previous_response_id] = previous_response_id
      elsif previous_response_id
        parameters[:previous_response_id] = previous_response_id
      elsif conversation_id
        parameters[:conversation] = conversation_id
      else
        create_conversation
      end

      messages_to_send = prepare_messages_for_api
      parameters[:input] = strip_responses(messages_to_send) unless messages_to_send.empty?

      if proxy
        uri = URI(PROXY_URL + "api.openai.com/v1/responses")
        send_request(uri, content_type: "json", parameters: parameters, method: "post")
      else
        client.responses.create(**parameters)
      end
    end

    # :reek:NilCheck
    # :reek:TooManyStatements
    def parse_response(response)
      if proxy && response.is_a?(Hash)
        response_messages = response.dig(:output).select do |output|
          output.dig(:type) == "message"
        end

        message_contents = response_messages.map do |message|
          message.dig(:content)
        end.flatten

        output_texts = message_contents.select do |content|
          content[:type] == "output_text"
        end

        text_response = output_texts.map { |output| output[:text] }.join
        response_id = response.dig(:id)
        response_status = response.dig(:status).to_sym
        response_model = response.dig(:model)
        response_usage = response.dig(:usage)&.slice(:input_tokens, :output_tokens, :total_tokens)

        if response.key?(:conversation)
          self.conversation_id = response.dig(:conversation, :id)
        end
      else        
        text_response = response.output_text
        response_id = response.id
        response_status = response.status
        response_model = response.model
        response_usage = response.usage.to_h.slice(:input_tokens, :output_tokens, :total_tokens)

        if response.conversation
          self.conversation_id = response.conversation.id
        end
      end
      image_filenames = extract_and_save_images(response) + extract_and_save_files(response)

      chat_response = {
        id: response_id,
        model: response_model,
        usage: response_usage || {},
        total_tokens: response_usage&.fetch(:total_tokens, 0),
        images: image_filenames
      }.compact

      response_content = if schema
        if text_response.nil? || text_response.empty?
          raise ArgumentError, "No text content in response to parse as JSON for schema: #{schema.inspect}"
        end
        JSON.parse(text_response, symbolize_names: true)
      else
        text_response
      end

      existing_message_position = messages.find_index do |message|
        message.dig(:response, :id) == response_id
      end

      message = {
        role: "assistant",
        content: response_content,
        response: chat_response,
        status: response_status
      }

      message.store(:images, image_filenames) unless image_filenames.empty?

      if existing_message_position
        messages[existing_message_position] = message
      else
        messages.push(message)
        message
      end
    end

    def cancel_request
      client.responses.cancel(previous_response_id)
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

      if proxy
        image_outputs = response.dig(:output).select { |output|
          output.dig(:type) == "image_generation_call"
        }
      else       
        image_outputs = response.output.select { |output|
          output.respond_to?(:type) && output.type == :image_generation_call
        }
      end

      return image_filenames if image_outputs.empty?

      response_id = proxy ? response.dig(:id) : response.id
      subfolder_path = create_images_folder(response_id)

      image_outputs.each_with_index do |output, index|
        if proxy
          next unless output.key?(:result) && output.dig(:result)
        else
          next unless output.respond_to?(:result) && output.result
        end

        warn_if_file_fails_to_save do
          result = proxy ? output.dig(:result) : output.result
          image_data = Base64.strict_decode64(result)

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
      yield
    rescue => error
      warn "Failed to save image: #{error.message}"
    end

    def validate_api_key
      openai_api_key_used = @api_key.start_with?("sk-proj")
      proxy_api_key_used = !openai_api_key_used
      proxy_enabled = proxy
      proxy_disabled = !proxy

      if openai_api_key_used && proxy_enabled
        raise WrongAPITokenUsedError, <<~STRING
          It looks like you're using an official API key from OpenAI with proxying enabled. When proxying is enabled you must use an OpenAI API key from prepend.me. Please disable proxy or update your API key before generating a response.
        STRING
      elsif proxy_api_key_used && proxy_disabled
        raise WrongAPITokenUsedError, <<~STRING
          It looks like you're using an unofficial OpenAI API key from prepend.me. When using an unofficial API key you must enable proxy before generating a response. Proxying is currently disabled, please enable it before generating a response.

          Example:

            chat = AI::Chat.new
            chat.proxy = true
            chat.user(...)
            chat.generate!
        STRING
      end
    end

    # :reek:FeatureEnvy
    # :reek:ManualDispatch
    # :reek:NestedIterators
    # :reek:TooManyStatements
    def extract_and_save_files(response)
      filenames = []

      if proxy
        message_outputs = response.dig(:output).select do |output|
          output.dig(:type) == "message"
        end
  
        outputs_with_annotations = message_outputs.map do |message|
          message.dig(:content).find do |content|
            content.dig(:annotations).length.positive?
          end
        end.compact
      else
        message_outputs = response.output.select do |output|
          output.respond_to?(:type) && output.type == :message
        end
  
        outputs_with_annotations = message_outputs.map do |message|
          message.content.find do |content|
            content.respond_to?(:annotations) && content.annotations.length.positive?
          end
        end.compact
      end

      return filenames if outputs_with_annotations.empty?

      response_id = proxy ? response.dig(:id) : response.id
      subfolder_path = create_images_folder(response_id)

      if proxy
        annotations = outputs_with_annotations.map do |output|
          output.dig(:annotations).find do |annotation|
            annotation.key?(:filename)
          end
        end.compact
  
        annotations.each do |annotation|
          container_id = annotation.dig(:container_id)
          file_id = annotation.dig(:file_id)
          filename = annotation.dig(:filename)
  
          warn_if_file_fails_to_save do
            file_content = retrieve_file(file_id, container_id: container_id)
            file_path = File.join(subfolder_path, filename)
            File.binwrite(file_path, file_content)
            filenames << file_path
          end
        end
      else
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
            file_content = retrieve_file(file_id, container_id: container_id)
            file_path = File.join(subfolder_path, filename)
            File.open(file_path, "wb") do |file|
              file.write(file_content.read)
            end
            filenames << file_path
          end
        end
      end
      filenames
    end

    # This is similar to ActiveJob's :polynomially_longer retry option
    # :reek:DuplicateMethodCall
    # :reek:UtilityFunction
    def calculate_wait(executions)
      # cap the maximum wait time to ~110 seconds
      executions = executions.clamp(1..10)
      jitter = 0.15
      ((executions**2) + (Kernel.rand * (executions**2) * jitter)) + 2
    end

    def timeout_request(duration)
      Timeout.timeout(duration) do
        yield
      end
    rescue Timeout::Error
      client.responses.cancel(previous_response_id)
    end

    # :reek:DuplicateMethodCall
    # :reek:TooManyStatements
    def wait_for_response(timeout)
        spinner = TTY::Spinner.new("[:spinner] Thinking ...", format: :dots)
        spinner.auto_spin
        api_response = retrieve_response(previous_response_id)
        number_of_times_polled = 0
        response = timeout_request(timeout) do
          status = if api_response.respond_to?(:status)
            api_response.status
          else 
            api_response.dig(:status)&.to_sym
          end

          while status != :completed
            some_amount_of_seconds = calculate_wait(number_of_times_polled)
            sleep some_amount_of_seconds
            number_of_times_polled += 1
            api_response = retrieve_response(previous_response_id)
            status = if api_response.respond_to?(:status)
              api_response.status
            else
              api_response.dig(:status)&.to_sym
            end
          end
          api_response
        end
        
        status = if api_response.respond_to?(:status)
          api_response.status
        else 
          api_response.dig(:status).to_sym
        end
        exit_message = status == :cancelled ? "request timed out" : "done!"
        spinner.stop(exit_message)
        response
    end

    def retrieve_response(previous_response_id)
      if proxy
        uri = URI(PROXY_URL + "api.openai.com/v1/responses/#{previous_response_id}")
        send_request(uri, content_type: "json", method: "get")
      else
        client.responses.retrieve(previous_response_id)
      end
    end

    def retrieve_file(file_id, container_id: nil)
      if proxy
        uri = URI(PROXY_URL + "api.openai.com/v1/containers/#{container_id}/files/#{file_id}/content")
        send_request(uri, method: "get")
      else
        container_content = client.containers.files.content
        file_content = container_content.retrieve(file_id, container_id: container_id)
      end
    end
  end
end
