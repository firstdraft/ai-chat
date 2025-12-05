# frozen_string_literal: true

module AI
  class Message < Hash
    def inspect
      ai(plain: !$stdout.tty?, index: false)
    end

    def pretty_inspect
      "#{inspect}\n"
    end

    # IRB's ColorPrinter calls pretty_print and re-colorizes text,
    # which escapes our ANSI codes. Write directly to output to bypass.
    def pretty_print(q)
      q.output << inspect
    end

    def to_html
      AI.wrap_html(ai(html: true, index: false))
    end
  end
end
