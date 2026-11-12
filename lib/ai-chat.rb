module AI
  HTML_PRE_STYLE = "background-color: #1e1e1e; color: #d4d4d4; padding: 1em; " \
                   "border-radius: 4px; overflow-x: auto; " \
                   "white-space: pre-wrap; word-wrap: break-word;"

  def self.wrap_html(content)
    html = "<pre style=\"#{HTML_PRE_STYLE}\">#{content}</pre>"
    html.respond_to?(:html_safe) ? html.html_safe : html
  end

  # Use AmazingPrint::Inspector directly to avoid conflicts with awesome_print gem
  # which also defines an `ai` method on Object
  def self.amazing_print(object, **options)
    AmazingPrint::Inspector.new(**options).awesome(object)
  end

  # Whether pretty_print is drawing into a console that shows color: IRB
  # (and so rails console) or Pry, with that console's color setting on.
  # IRB always hands its printer colorize: true and leaves the real decision
  # (a color terminal, and no --nocolorize) to IRB::Color.colorable?.
  #
  # inspect never adds color, because its String also ends up in places that
  # can't read terminal escape codes: the Better Errors console in the
  # browser, log files, ERB. Asking $stdout.tty? doesn't tell those apart: a
  # Rails server started from a terminal has a TTY on $stdout, too.
  def self.color_printer?(q)
    if defined?(IRB::ColorPrinter) && q.is_a?(IRB::ColorPrinter)
      q.instance_variable_get(:@colorize) != false && IRB::Color.colorable?
    elsif defined?(Pry::ColorPrinter) && q.is_a?(Pry::ColorPrinter)
      Pry.config.color
    else
      false
    end
  end

  # Recursively truncate base64 data URIs in nested structures for cleaner output
  def self.truncate_data_uris(obj)
    case obj
    when Hash
      obj.transform_values { |v| truncate_data_uris(v) }
    when Array
      obj.map { |v| truncate_data_uris(v) }
    when String
      truncate_data_uri(obj)
    else
      obj
    end
  end

  def self.truncate_data_uri(str)
    return str unless str.is_a?(String) && str.start_with?("data:") && str.include?(";base64,")

    match = str.match(/\A(data:[^;]+;base64,)(.+)\z/)
    return str unless match

    prefix = match[1]
    data = match[2]
    "#{prefix}#{data[0, 20]}... (#{data.length} chars)"
  end
end

require_relative "ai/message"
require_relative "ai/items"
require_relative "ai/chat"

# Load amazing_print extension if amazing_print is available
begin
  require_relative "ai/amazing_print"
rescue LoadError
  # amazing_print not available, skip custom formatting
end
