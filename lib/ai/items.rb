# frozen_string_literal: true

require "delegate"

module AI
  class Items < SimpleDelegator
    def initialize(response, conversation_id:)
      super(response)
      @conversation_id = conversation_id
    end

    def to_html
      AI.wrap_html(build_output(html: true))
    end

    def inspect
      build_output(html: false, plain: !$stdout.tty?)
    end

    def pretty_inspect
      "#{inspect}\n"
    end

    def pretty_print(q)
      q.output << inspect
    end

    private

    def build_output(html: false, plain: false)
      box = build_box
      items_output = data.ai(html: html, plain: plain, limit: 100, indent: 2, index: true)

      if html
        "<pre>#{box}</pre>\n#{items_output}"
      else
        "#{box}\n#{items_output}"
      end
    end

    def build_box
      box_width = 78
      inner_width = box_width - 4

      lines = []
      lines << "┌#{"─" * (box_width - 2)}┐"
      lines << "│ Conversation: #{@conversation_id.to_s.ljust(inner_width - 14)} │"
      lines << "│ Items: #{data.length.to_s.ljust(inner_width - 7)} │"
      lines << "└#{"─" * (box_width - 2)}┘"

      lines.join("\n")
    end
  end
end
