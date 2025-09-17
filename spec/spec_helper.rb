# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "bundler/setup"
require "yabeda/activejob"
require "yabeda/rspec"
require_relative "support/rails_app"
require "rspec/rails"
require "simplecov"
SimpleCov.start

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include ActiveJob::TestHelper

  Kernel.srand config.seed
  config.order = :random

  config.before(:suite) do
    Yabeda::ActiveJob.install!
  end
end

RSpec::Matchers.define_negated_matcher :not_increment_yabeda_counter, :increment_yabeda_counter
