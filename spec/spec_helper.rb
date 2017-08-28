# ------------------------------------------------------------------------------
# This file is used by direct rspec tests.  It is ignored by onceover, which
# generates the spec_helper.rb file for its spec matrix tests.
# ------------------------------------------------------------------------------

require 'puppetlabs_spec_helper/module_spec_helper'
require 'tmpdir'
require 'yaml'
require 'fileutils'

ctl_repo_dir = File.expand_path('..',File.dirname(__FILE__))
spec_dir     = File.dirname(__FILE__)
hiera_yaml   = File.join('..', 'hiera.yaml')
fixture_path = File.expand_path('fixtures', spec_dir)
file_utils   = ENV['DEBUG'] == 'yes' ? FileUtils::Verbose : FileUtils

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
      factset_name =  File.basename(file).sub(/\.facts\.json/,'')

      facts = fs['values'] #.reject{|k,v| k =~ /^(fact_keys|to_strip_out)$/ }

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


def spec_test_matrix(opts = {}, &block)
  environments.each do |env_name|
    context "in environment '#{env_name}'" do
      factsets.each do |fs_name,fs_facts|
        context "on #{fs_name} (derived from #{fs_facts['clientcert']})" do
          let(:facts){ fs_facts }
          let(:environment){ env_name }
            class_exec(fs_facts, fs_name, env_name, &block)
        end
      end
    end
  end
end


RSpec.configure do |c|
  c.default_facts = { :custom_nothing => 0 }

  ### TODO: Add JUnit output in case people want to use that?
  ### requires gem 'rspec_junit_formatter'
  ### c.add_formatter('RSpecJUnitFormatter', File.expand_path('spec.xml',spec_dir))
  c.environmentpath = File.expand_path('environments', fixture_path)

  c.trusted_node_data = true
  c.before(:suite) do
    # Create Hiera v3 hierarchies because rspec-puppet doesn't
    # expose enough of the v4/v5 yet
    h = YAML.load_file File.expand_path( hiera_yaml, spec_dir )
    _hiera_yaml = File.expand_path('hiera.yaml', fixture_path)
    h_ver =  h.fetch('version', 3)
    if h_ver == 3
      file_utils.cp_p(h, _hiera_yaml)
    elsif h_ver == 4
      h3 = {
        :backends => ['yaml'],
        :yaml => { :datadir => File.expand_path(h['datadir'], ctl_repo_dir) },
        :hierarchy => h['hierarchy'].map{|x| x.fetch('path',nil) || x.fetch('paths',nil)  }.flatten,
        :logger =>   'console', #or 'puppet'
      }
      File.write( _hiera_yaml,  h3.to_yaml)
      c.hiera_config = _hiera_yaml
    end

    # sanitize hieradata
    if defined?(hieradata)
      set_hieradata(hieradata.gsub(':','_'))
    elsif defined?(class_name)
      set_hieradata(class_name.gsub(':','_'))
    end
  end

  c.after(:each) do
    # clean up the mocked environmentpath
    FileUtils.rm_rf(@spec_global_env_temp)
    @spec_global_env_temp = nil
  end


  c.before(:each) do
    @spec_global_env_temp = Dir.mktmpdir('simpspec')

    if defined?(environment)
      #set_environment(environment)
      FileUtils.mkdir_p(File.join(@spec_global_env_temp,environment.to_s))
    end

    # ensure the user running these tests has an accessible environmentpath
    Puppet[:environmentpath] = @spec_global_env_temp
    Puppet[:user] = Etc.getpwuid(Process.uid).name
    Puppet[:group] = Etc.getgrgid(Process.gid).name
    if ENV.fetch('DEBUG','no') == 'yes'
      Puppet.debug=true
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
    end
  end
end


# Fail on broken symlinks to module fixtures
Dir.glob("#{RSpec.configuration.module_path}/*").each do |dir|
  begin
    Pathname.new(dir).realpath
  rescue
    fail "ERROR: The module '#{dir}' is not installed. Tests cannot continue."
  end
end

# Work-around for 'cannot load backend' failure with Puppet 4
Dir["#{fixture_path}/modules/*/lib"].entries.each do |lib_dir|
  $LOAD_PATH << lib_dir
end
