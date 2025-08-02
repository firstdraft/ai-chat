require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("ai" => "AI")
loader.setup

require_relative "ai/chat"
