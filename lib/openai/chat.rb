# frozen_string_literal: true

require "zeitwerk"

Zeitwerk::Loader.new.then do |loader|
  loader.tag = "openai-chat"
  loader.inflector.inflect("openai" => "OpenAI")
  loader.push_dir "#{__dir__}/.."
  loader.setup
end

module OpenAI
  # Main namespace.
  class Chat
    def self.loader(registry = Zeitwerk::Registry)
      @loader ||= registry.loaders.each.find { |loader| loader.tag == "openai-chat" }
    end
  end
end
