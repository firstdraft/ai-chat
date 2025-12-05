module AI
  HTML_PRE_STYLE = "background-color: #1e1e1e; color: #d4d4d4; padding: 1em; white-space: pre-wrap; word-wrap: break-word;"

  def self.wrap_html(html)
    html = html.gsub("<pre>", "<pre style=\"#{HTML_PRE_STYLE}\">")
    html.respond_to?(:html_safe) ? html.html_safe : html
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
