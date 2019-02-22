source 'https://rubygems.org'

# Specify your gem's dependencies in roo-xls.gemspec
gemspec

roo_opts = {}
if !ENV['TRAVIS']
  roo_opts[:path] = ::File.expand_path('../../roo', __FILE__)
elsif Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.3.0")
  roo_opts[:github] = 'roo-rb/roo'
end

gem 'roo', '>= 2.0.0beta1', roo_opts

group :test do
  # additional testing libs
  gem 'webmock'
  gem 'shoulda'
  gem 'rspec', '>= 3.0.0'
  gem 'vcr'
  gem 'simplecov', '>= 0.9.0', :require => false
  gem 'coveralls', :require => false
end

group :local_development do
  gem 'terminal-notifier-guard', require: false if RUBY_PLATFORM.downcase.include?('darwin')
  gem 'guard-rspec', '>= 4.3.1' ,require: false
  gem 'guard-bundler', require: false
  gem 'guard-preek', require: false
  gem 'guard-rubocop', require: false
  gem 'guard-reek', github: 'pericles/guard-reek', require: false
  gem 'pry'
  gem 'appraisal'
end
