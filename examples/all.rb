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

# Basic multimodal tests (images, PDFs, files)
require_relative "04_multimodal"

# Comprehensive file handling tests
require_relative "05_file_handling_comprehensive"

# Basic structured output tests
require_relative "06_structured_output"

# Comprehensive structured output tests (all 6 schema formats)
require_relative "07_structured_output_comprehensive"

# Edge cases and error handling
require_relative "09_edge_cases"

# Additional usage patterns
require_relative "10_additional_patterns"

# Mixed content types (images + files in single message)
require_relative "11_mixed_content"

# Image generation
require_relative "12_image_generation"

# Code Interpreter
require_relative "13_code_interpreter"

# Background Mode
require_relative "14_background_mode"

# Conversations
require_relative "15_conversation_features_comprehensive"

# Schema Generation
require_relative "16_schema_generation"

# Proxy
require_relative "17_proxy"
