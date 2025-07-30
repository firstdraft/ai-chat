require_relative "ai/chat"

# Load amazing_print extension if amazing_print is available
begin
  require_relative "ai/amazing_print"
rescue LoadError
  # amazing_print not available, skip custom formatting
end
