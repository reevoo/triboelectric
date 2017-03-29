require "simplecov"
SimpleCov.minimum_coverage 100
SimpleCov.start

require "bundler/setup"
require "triboelectric"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
