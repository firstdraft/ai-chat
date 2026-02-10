# frozen_string_literal: true

module AI
  # NOTE: This is intentionally *not* a SimpleDelegator.
  #
  # IRB's default inspector uses PP, and PP has special handling for Delegator
  # instances that unwraps them (via __getobj__) before printing. That causes
  # IRB to display the underlying OpenAI cursor page instead of our custom
  # formatted output.
  #
  # By using a plain wrapper + method_missing delegation, `chat.get_items`
  # displays nicely in IRB/Rails console while still forwarding API helpers
  # like `.data`, `.has_more`, etc.
  class Items
    def initialize(response, conversation_id:)
      @response = response
      @conversation_id = conversation_id
    end

    attr_reader :response

    def data
      response.data
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

    def method_missing(method_name, *args, &block)
      return super unless response.respond_to?(method_name)

      response.public_send(method_name, *args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      response.respond_to?(method_name, include_private) || super
    end

    private

    def build_output(html: false, plain: false)
      box = build_box
      items_output = AI.amazing_print(data, html: html, plain: plain, limit: 100, indent: 2, index: true)

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
