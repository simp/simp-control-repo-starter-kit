source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'r10k'
gem 'hiera-eyaml'

group :test do
  gem 'rake'
  # This matches the currently installed PE version
  gem 'puppet', ENV['PUPPET_VERSION'] || '4.8.2'
  gem 'puppet-lint'
  gem 'puppetlabs_spec_helper'
  gem 'rspec', '~> 3.0'
  gem 'simp-rspec-puppet-facts', ENV.fetch('SIMP_RSPEC_PUPPET_FACTS_VERSION', '~> 1.3'), :require => false
  gem 'simp-rake-helpers', ENV.fetch('SIMP_RAKE_HELPERS_VERSION', '~> 3.0'), :require => false
  gem 'metadata-json-lint'
end

group :development do
  gem 'puppet-strings'
  gem 'pry'
  gem 'pry-doc'
end

group :system_tests do
  gem 'beaker-rspec'
  gem 'simp-beaker-helpers', ENV.fetch('SIMP_BEAKER_HELPERS_VERSION', '~> 1.5')
end