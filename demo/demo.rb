#!/usr/bin/env ruby

# Main demo runner - executes all test suites

# Core functionality tests
require_relative "demo_core"

# Configuration tests (API keys, models, reasoning)
require_relative "demo_configuration"

# Structured output tests
require_relative "demo_structured_output"

# Multimodal tests (images, PDFs, files)
require_relative "demo_multimodal"

# Advanced usage patterns
require_relative "demo_advanced_usage"

puts "\n=== All AI::Chat demos completed ==="
