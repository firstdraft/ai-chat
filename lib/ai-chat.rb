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
