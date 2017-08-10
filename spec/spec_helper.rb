# ------------------------------------------------------------------------------
# This file is used by direct rspec tests.  It is ignored by onceover, which
# generates the spec_helper.rb file for its spec matrix tests.
# ------------------------------------------------------------------------------

require 'puppetlabs_spec_helper/module_spec_helper'
require 'tmpdir'
require 'yaml'

spec_dir     = File.dirname(__FILE__)
hiera_yaml   = File.join(spec_dir, 'hiera.yaml')
fixture_path = File.expand_path( spec_dir, 'fixtures')

ALL_ENVIRONMENTS = ['production']

# read all the *.json files under spec/factsets and return a Hash
def factsets
  factsets = {}
  factset_files = Dir[File.join(File.dirname(__FILE__),'factsets','*.json')]
  factset_files.each do |file|
    fs = YAML.load_file file

    # NOTE: This data structure might change in the future,
    #   see: https://tickets.puppetlabs.com/browse/PUP-6040
    if !(fs.key?('values') && fs.key?('name'))
      warn '='*80
      warn "WARNING: Factset '#{file}' does not have the correct structure―SKIPPING."
      warn "         Was it captured using `puppet facts --environment production`?"
      warn '='*80
    else
      factset_name =  File.basename(file).sub(/\.json/,'')

      # strip out any ::role and ::self_provisioned facts
      facts = fs['values'].reject{|k,v| k =~ /^(role|self_provisioned)$/ }

      factsets[ factset_name ] =  facts
    end
  end
  factsets
end

def environments
  # `rp_env` is the default spec-testing environment, but it's unlikely to
  # match any tiers within the control repo's hiera hierarchy.  Using it
  # can be useful to identify broken or missing default cases.
  #
  # Set the environment variable `RSPEC_PUPPET_ENVS` to pass in environments as
  # a comma-delimited list.
  envs = ENV.fetch('RSPEC_PUPPET_ENVS', 'rp_env').split(',')
  if envs.first =~ /^ALL$/
    # TODO: maybe this should check the control repo's git branches?
    ALL_PUPPET_ENVIRONMENTS
  else
    envs
  end
end

RSpec.configure do |c|
  c.default_facts = { :custom_nothing => 0 }
  c.parser = 'future'

  ### Also add JUnit output in case people want to use that
  ### requires gem 'rspec_junit_formatter'
  ### c.add_formatter('RSpecJUnitFormatter', File.expand_path('spec.xml',spec_dir))

  c.hiera_config = File.expand_path(File.join(__FILE__, '../hiera.yaml'))
end

# Fail on broken symlinks to module fixtures
Dir.glob("#{RSpec.configuration.module_path}/*").each do |dir|
  begin
    Pathname.new(dir).realpath
  rescue
    fail "ERROR: The module '#{dir}' is not installed. Tests cannot continue."
  end
end

