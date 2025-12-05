require "amazing_print"

# Fix AmazingPrint's colorless method to strip HTML tags in addition to ANSI codes.
# Without this, alignment is broken when html: true because colorless_size
# doesn't account for <kbd> tag lengths.
# TODO: Remove if https://github.com/amazing-print/amazing_print/pull/146 is merged.
module AmazingPrint
  module Formatters
    class BaseFormatter
      alias_method :original_colorless, :colorless

      def colorless(string)
        result = original_colorless(string)
        result.gsub(/<kbd[^>]*>|<\/kbd>/, "")
      end
    end
  end
end

# :reek:IrresponsibleModule
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

    # :reek:FeatureEnvy
    def format_ai_chat(chat)
      vars = chat.inspectable_attributes.map do |(name, value)|
        [name.to_s, value]
      end
      format_object(chat, vars)
    end

    # :reek:TooManyStatements
    # :reek:DuplicateMethodCall
    def format_object(object, vars)
      data = vars.map do |(name, value)|
        name = colorize(name, :variable) unless @options[:plain]
        "#{name}: #{inspector.awesome(value)}"
      end

      lt = @options[:html] ? "&lt;" : "<"
      gt = @options[:html] ? "&gt;" : ">"

      if @options[:multiline]
        "##{lt}#{object.class}\n#{data.map { |line| "  #{line}" }.join("\n")}\n#{gt}"
      else
        "##{lt}#{object.class} #{data.join(", ")}#{gt}"
      end
    end
  end
end

AmazingPrint::Formatter.send(:include, AmazingPrint::AI)
