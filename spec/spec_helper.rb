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

def with_env(env)
  old_env = {}
  env.each do |var, val|
    old_env[var] = ENV[var]
    ENV[var] = val
  end
  yield
  old_env.each do |var, val|
    ENV[var] = val
  end
end
