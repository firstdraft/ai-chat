require "amazing_print"

module AmazingPrint
  module AI
    def self.included(base)
      base.send :alias_method, :cast_without_ai, :cast
      base.send :alias_method, :cast, :cast_with_ai
    end

    def cast_with_ai(object, type)
      case object
      when ::AI::Chat
        :ai_object
      else
        cast_without_ai(object, type)
      end
    end

    private

    def awesome_ai_object(object)
      case object
      when ::AI::Chat
        format_ai_chat(object)
      else
        awesome_object(object)
      end
    end

    def format_ai_chat(chat)
      vars = []
      
      # Format messages with truncation
      if chat.instance_variable_defined?(:@messages)
        messages = chat.instance_variable_get(:@messages).map do |msg|
          truncated_msg = msg.dup
          if msg[:content].is_a?(String) && msg[:content].length > 80
            truncated_msg[:content] = msg[:content][0..77] + "..."
          end
          truncated_msg
        end
        vars << ["@messages", messages]
      end
      
      # Add other variables (except sensitive ones)
      skip_vars = [:@api_key, :@client, :@messages]
      chat.instance_variables.sort.each do |var|
        next if skip_vars.include?(var)
        value = chat.instance_variable_get(var)
        vars << [var.to_s, value] unless value.nil?
      end

      format_object(chat, vars)
    end

    def format_object(object, vars)
      data = vars.map do |(name, value)|
        name = colorize(name, :variable) unless @options[:plain]
        "#{name}: #{inspector.awesome(value)}"
      end

      if @options[:multiline]
        "#<#{object.class}\n#{data.map { |line| "  #{line}" }.join("\n")}\n>"
      else
        "#<#{object.class} #{data.join(', ')}>"
      end
    end
  end
end

AmazingPrint::Formatter.send(:include, AmazingPrint::AI)
