require 'r10k/puppetfile'
require 'erb'
require 'json'

CLEAN << ['.fixtures.yml', 'spec/fixtures/modules']

namespace :spec do

def find_control_repo_root
  root = Dir.pwd
  until File.exist?(File.expand_path('./environment.conf',root)) do
    # Throw an exception if we can't go any further up
    throw "Could not file root of the controlrepo anywhere above #{Dir.pwd}" if root == File.expand_path('../',root)

    # Step up and try again
    root = File.expand_path('../',root)
  end
  root
end


    def fixtures
      _root = find_control_repo_root

      # Load up the Puppetfile using R10k
      puppetfile = R10K::Puppetfile.new(_root)
      fail 'Could not load Puppetfile' unless puppetfile.load
      modules = puppetfile.modules

      # Iterate over everything and seperate it out for the sake of readability
      symlinks = []
      forge_modules = []
      repositories = []

      modules.each do |mod|
        logger.debug "Converting #{mod.to_s} to .fixtures.yml format"
        # This logic could probably be cleaned up. A lot.
        if mod.is_a? R10K::Module::Forge
          if mod.expected_version.is_a?(Hash)
            # Set it up as a symlink, because we are using local files in the Puppetfile
            symlinks << {
              'name' => mod.name,
              'dir' => mod.expected_version[:path]
            }
          elsif mod.expected_version.is_a?(String)
            # Set it up as a normal firge module
            forge_modules << {
              'name' => mod.name,
              'repo' => mod.title,
              'ref' => mod.expected_version
            }
          end
        elsif mod.is_a? R10K::Module::Git
          # Set it up as a git repo
          repositories << {
              'name' => mod.name,
              # I know I shouldn't be doing this, but trust me, there are no methods
              # anywhere that expose this value, I looked.
              'repo' => mod.instance_variable_get(:@remote),
              'ref' => mod.version
            }
        end
      end

      # also add symlinks for anything that is in environment.conf
      code_dirs = config['modulepath']
      code_dirs.delete_if { |dir| dir[0] == '$'}
      code_dirs.each do |dir|
        # We need to traverse down into these directories and create a symlink for each
        # module we find because fixtures.yml is expecting the module's root not the
        # root of modulepath
        Dir["#{dir}/*"].each do |mod|
          symlinks << {
            'name' => File.basename(mod),
            'dir' => Pathname.new(File.expand_path(mod)).relative_path_from(Pathname.new(_root))#File.expand_path(mod)
          }
        end
      end

      # Use an ERB template to write the files
      evaluate_template('.fixtures.yml.erb',binding)
    end

    def self.evaluate_template(template_name,bind)
      logger.debug "Evaluating template #{template_name}"
      template_dir = File.expand_path('templates',File.dirname(__FILE__))
      template = File.read(File.expand_path("./#{template_name}",template_dir))
      ERB.new(template, nil, '-').result(bind)
    end

    def config
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
  desc 'Writes a `fixtures.yml` file based on the Puppetfile'
  task :generate_fixtures do
    cr_root = find_control_repo_root
    raise ".fixtures.yml already exits, we won't overwrite because we are scared" if File.exists?(File.expand_path('./.fixtures.yml',cr_root))
    File.write(File.expand_path('./.fixtures.yml',cr_root),fixtures)
  end
end

