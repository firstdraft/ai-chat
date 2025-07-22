# frozen_string_literal: true

require 'zeitwerk'

Zeitwerk::Loader.new.then do |loader|
  loader.tag = 'openai-chat'
  loader.push_dir "#{__dir__}/.."
  loader.setup
end

module Openai
  # Main namespace.
  module Chat
    def self.loader(registry = Zeitwerk::Registry)
      @loader ||= registry.loaders.each.find { |loader| loader.tag == 'openai-chat' }
    end
  end
end
