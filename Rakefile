# frozen_string_literal: true

require 'bundler/setup'
require 'reek/rake/task'
require 'rspec/core/rake_task'

Reek::Rake::Task.new
RSpec::Core::RakeTask.new { |task| task.verbose = false }

desc 'Run code quality checks'
task quality: %i[reek]

task default: %i[quality spec]
