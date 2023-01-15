require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
# require 'coveralls/rake/task'

# RSpec
RSpec::Core::RakeTask.new(:spec)

# Coveralls
# Coveralls::RakeTask.new

default_task = [:spec]
# default_task << 'coveralls:push' # This is prepared for CI

task default: default_task
