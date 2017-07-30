source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'puppet', ENV['PUPPET_VERSION'] || '4.8.2'
gem 'r10k'
gem 'hiera-eyaml'

# for testing
gem 'puppet-lint'
gem 'puppetlabs_spec_helper'
gem 'rspec', '~> 3.0'
gem 'simp-rspec-puppet-facts', :require => false
gem 'simp-rake-helpers'

# for debugging ruby code (tests, etc)
gem 'pry' if ENV['PRY'] == 'yes'
