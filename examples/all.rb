#!/usr/bin/env ruby

# Main example runner - executes all test suites
#
# This comprehensive test suite demonstrates and validates all features
# of the AI::Chat gem, serving as both documentation and verification.

puts "=== AI::Chat Comprehensive Test Suite ==="
puts "Running all example scripts to validate functionality..."
puts

# Quick overview
require_relative "01_quick"

# Core functionality tests
require_relative "02_core"

# Configuration tests (API keys, models, reasoning)
require_relative "03_configuration"

# Basic multimodal tests (images, PDFs, files)
require_relative "04_multimodal"

# Comprehensive file handling tests
require_relative "05_file_handling_comprehensive"

# Basic structured output tests
require_relative "06_structured_output"

# Comprehensive structured output tests (all 6 schema formats)
require_relative "07_structured_output_comprehensive"

# Advanced usage patterns
require_relative "08_advanced_usage"

# Edge cases and error handling
require_relative "09_edge_cases"

# Additional usage patterns
require_relative "10_additional_patterns"

# Mixed content types (images + files in single message)
require_relative "11_mixed_content"

puts "\n=== All AI::Chat examples completed ==="
puts
puts "Summary:"
puts "- Core functionality: Basic chat, messages, responses"
puts "- Configuration: API keys, models, reasoning effort"
puts "- Structured output: 6 different schema formats supported"
puts "- File handling: PDFs, text files, URLs, Rails uploads"
puts "- Multimodal: Images, multiple files, mixed content"
puts "- Advanced: Chaining, web search, error handling"
puts "- Edge cases: Validation, error messages, introspection"
