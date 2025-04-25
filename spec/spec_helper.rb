# frozen_string_literal: true

require "ai-chat"
require "webmock/rspec"
require "factory_bot"
require "vcr"

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data("<AI_TOKEN>") do |interaction|
    ENV["AI_TOKEN"] || ENV["OPENAI_TOKEN"] || "dummy_token"
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run VCR for all specs
  config.around(:each) do |example|
    vcr_tag = example.metadata[:vcr]

    if vcr_tag
      cassette_name = (vcr_tag == true) ? example.full_description : vcr_tag
      VCR.use_cassette(cassette_name, record: :once) do
        example.run
      end
    else
      example.run
    end
  end
end

# Create fixture directory if it doesn't exist
FileUtils.mkdir_p("spec/fixtures") unless Dir.exist?("spec/fixtures")
