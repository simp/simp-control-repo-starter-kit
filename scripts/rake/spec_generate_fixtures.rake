require 'r10k/puppetfile'
require 'erb'
require 'json'
require 'rake/clean'
require 'fileutils'

CLEAN.include ['.fixtures.yml', 'spec/fixtures/modules']

# Most of this was quickly ripped from Onceover (https://github.com/dylanratcliffe/onceover)
class CrSpecHelpers
  def CrSpecHelpers.find_control_repo_root
    root = Dir.pwd
    until File.exist?(File.expand_path('./environment.conf',root)) do
      # Throw an exception if we can't go any further up
      throw "Could not file root of the control repo anywhere above #{Dir.pwd}" if root == File.expand_path('../',root)

      # Step up and try again
      root = File.expand_path('../',root)
    end
    root
  end


  def CrSpecHelpers.fixtures
    _root = find_control_repo_root
    # Load up the Puppetfile using R10k
    puppetfile = R10K::Puppetfile.new(_root)
    fail 'Could not load Puppetfile' unless puppetfile.load
    modules = puppetfile.modules

    # Iterate over everything and seperate it out for the sake of readability
    symlinks = []
    forge_modules = []
    repositories = []

    _processed = 0
    _size=modules.size
    modules.each do |mod|
      warn "Converting #{mod.to_s} to .fixtures.yml format" if (Rake.verbose == true)
      # This logic could probably be cleaned up. A lot.
      if mod.is_a? R10K::Module::Forge
        _repo = {}
        if mod.expected_version.is_a?(Hash)
          # Set it up as a symlink, because we are using local files in the Puppetfile
          _symlink = {
            'name' => mod.name,
            'dir' => mod.expected_version[:path]
          }
          symlinks << _symlink
          _processed += 1
          pp _symlink
        elsif mod.expected_version.is_a?(String)
          # Set it up as a normal forge module
          _forge_module << {
e,
            'repo' => mod.title,
            'ref' => mod.expected_version
          }
          forge_modules << _forge_module
          _processed += 1
          pp _forge_module
        end
      elsif mod.is_a? R10K::Module::Git
        # Set it up as a git repo
        _repo = {
          'name' => mod.name,
          # I know I shouldn't be doing this, but trust me, there are no methods
          # anywhere that expose this value, I looked.
          'repo' => mod.instance_variable_get(:@remote),
          'ref' => mod.send(:desired_ref) # faster than .version
        }
        repositories << _repo
        _processed += 1
        pp _repo
      end
      warn "Processed: [#{_processed}/#{_size}] modules" if (Rake.verbose == true)
    end


    warn 'end of module conversion'

    extra_fixtures_file = File.join(_root, '.fixtures.extra.yml')
    if File.exists? extra_fixtures_file
      _f = YAML.load_file( extra_fixtures_file )
      _fx = _f['fixtures']
      if _r = _fx.fetch('repositories',nil)
        _repositories = _r.map{|k,v| {'name' => k, 'repo' => v['repo'], 'ref' => v['ref']}}
        warn "Adding #{_repositories.size} extra fixtures in '#{extra_fixtures_file}':"
        _repositories.each{|__r| pp __r}
        repositories = (repositories + _repositories).flatten
      end
    end

    # also add symlinks for anything that is in environment.conf
    code_dirs = CrSpecHelpers.config['modulepath']
    code_dirs.delete_if { |dir| dir[0] == '$'}
    code_dirs.each do |dir|
      # We need to traverse down into these directories and create a symlink for each
      # module we find because fixtures.yml is expecting the module's root not the
      # root of modulepath
      Dir["#{dir}/*"].each do |mod|
        _mod = Pathname.new(mod)
        if _mod.relative?
          _fixtures_dir = Pathname.new('spec/fixtures/modules')
          _dir = _mod.relative_path_from(_fixtures_dir)
        else
          _dir = Pathname.new(File.expand_path(mod))
                  end

        symlinks << {
          'name' => File.basename(mod),
          'dir' => _dir
        }
      end
    end

    # Use an ERB template to write the files
    CrSpecHelpers.evaluate_template('.fixtures.yml.erb',binding)
  end

  def CrSpecHelpers.evaluate_template(template_name,bind)
    warn  "Evaluating template #{template_name}"
    root_dir     = CrSpecHelpers.find_control_repo_root
    template_dir = File.expand_path('templates',File.dirname(__FILE__))
    template     = File.read(File.expand_path("./#{template_name}",template_dir))
    ERB.new(template, nil, '-').result(bind)
  end

  def CrSpecHelpers.config
    #Parse the file
    _environment_conf = File.join( find_control_repo_root , 'environment.conf' )
    warn "Reading #{_environment_conf}"
    env_conf = File.read(_environment_conf)
    env_conf = env_conf.split("\n")

    # Delete commented out lines
    env_conf.delete_if { |l| l =~ /^\s*#/}

    # Map the lines into a hash
    environment_config = {}
    env_conf.each do |line|
      environment_config.merge!(Hash[*line.split('=').map { |s| s.strip}])
    end

    # Finally, split the modulepath values and return
    begin
      environment_config['modulepath'] = environment_config['modulepath'].split(':')
    rescue
      raise "modulepath was not found in environment.conf, don't know where to look for roles & profiles"
    end
    return environment_config
  end
end

namespace :spec do
  desc <<-EOM
    Writes a `fixtures.yml` file based on the Puppetfile

    Args:
      * :replace => Will replace an existing `.fixtures.yaml`.
                    Accepts 'true' and 'false'. Defaults to 'true'.
                    Env var: OVERWRITE_FIXTURES=yes  # 'yes' or 'no'
  EOM
  task :generate_fixtures, [:replace] do |t,args|
    args.with_defaults(:replace => (ENV.fetch('OVERWRITE_FIXTURES','yes')=='yes').to_s )
    replace = args[:replace] == 'true' ? true : false

    cr_root = CrSpecHelpers.find_control_repo_root
    fx_file = File.expand_path('./.fixtures.yml',cr_root)
    if File.exists?(fx_file)
      if replace
        FileUtils.rm_f(fx_file)
      else
        fail "ERROR: .fixtures.yml already exists, we won't overwrite because we are " +
             "scared (hint: run `rake clean`)"
      end
    end
    fixtures = CrSpecHelpers.fixtures
    warn "Writing '#{fx_file}'"
    File.write(fx_file,fixtures)
  end

end

task :spec_prep => ['spec:generate_fixtures']
