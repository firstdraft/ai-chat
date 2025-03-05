# frozen_string_literal: true

require "zeitwerk"

Zeitwerk::Loader.new.then do |loader|
  loader.tag = "ai-chat"
  loader.push_dir "#{__dir__}/.."
  loader.setup
end

module Ai
  # Main namespace.
  module Chat
    def self.loader registry = Zeitwerk::Registry
        @loader ||= registry.loaders.find { |loader| loader.tag == "ai-chat" }
  end

  end
end
