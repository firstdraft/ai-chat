# frozen_string_literal: true

module AI
  class Message < Hash
    def inspect
      formatted(plain: true)
    end

    def pretty_inspect
      "#{inspect}\n"
    end

    # The console's path, and so the only place color is added (see
    # AI.color_printer?). IRB's ColorPrinter re-colorizes text, which
    # escapes our ANSI codes, so write directly to output to bypass it,
    # but flush first: inside an Array, PP is still buffering the "[" and
    # earlier separators, so an unflushed write lands ahead of them.
    def pretty_print(q)
      q.flush
      q.output << formatted(plain: !AI.color_printer?(q))
    end

    def to_html
      AI.wrap_html(AI.amazing_print(display_hash, html: true, index: false))
    end

    private

    def formatted(plain:)
      AI.amazing_print(display_hash, plain: plain, index: false)
    end

    def display_hash
      AI.truncate_data_uris(to_h)
    end
  end
end
