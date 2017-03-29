require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "reevoocop/rake_task"
require "bundler/audit/task"

RSpec::Core::RakeTask.new(:spec)
ReevooCop::RakeTask.new(:reevoocop)
Bundler::Audit::Task.new

task default: [:spec, :reevoocop, "bundle:audit"]
