require 'find'


class SpecTestMismatchFinder

  def initialize(opts = {
    :verbose => false,
    :trace   => false,
  })
    @pp_types     ={'class'=>[]} # types mapping to names
    @pp_file_subjects     = {} # files mapping to 0+ [type,name] pairs
    @pp_subject_files     = {} # names mapping to 1+ files
    @spec_subjects ={'class'=>[]}
    @spec_file_subjects     = {} # files mapping to 0+ [type,name] pairs
    @pp_file_paths = ['site', 'modules/site', 'modules/profiles', 'modules/roles']
    @class_whitelist_patterns = /(profile|role|site)/
    @whitelist_pattern =  /^\s*(class|define)\s+((profiles?|roles?|site)\:\:(([a-zA-Z0-9][a-zA-Z0-9_]+(::)?)+))/
    @verbose = opts[:verbose]
    @trace = opts[:trace]
  end

  def control_repo_root
    return(@control_repo_root) if @control_repo_root
    root = Dir.pwd
    until File.exist?(File.expand_path('./environment.conf',root)) do

      # Throw an exception if we can't go any further up
      if root == File.expand_path('../',root)
        throw "Could not file root of the control repo anywhere above #{Dir.pwd}"
      end

      # Step up and try again
      root = File.expand_path('../',root)
    end
    @control_repo_root = root
  end

  def tally_spec_tests
    warn "==== #{self.class.name}.#{__method__.to_s}" if @trace
    spec_path = File.join( control_repo_root, 'spec' )
    Dir["#{spec_path}/{classes,defines}"].each do |search_path|
      next unless File.exist? search_path
      Find.find( File.directory?(search_path) ? "#{search_path}/" : search_path ) do |path|
        next unless File.file? path
        next unless path =~ /_spec\.rb$/
        @spec_file_subjects[path] ||= []
        classes = File.readlines(path).each do |line|
          next unless line =~ /^\s*describe\s+(['"]|%[qQ].)?([a-z](([a-zA-Z0-9][a-zA-Z0-9_]+(::)?)+))/
          _subj = $2
          _type = File.basename(search_path).sub(/(es|s)$/,'')
          @spec_subjects[_type] ||= []
          @spec_subjects[_type] <<  _subj
          @spec_file_subjects[path] << _subj
           warn "spec #{_type} #{_subj}: #{path.sub(/^#{control_repo_root}\//,'')}" if @trace
        end
      end
    end
  end

  def full_paths(paths)
    warn "==== #{self.class.name}.#{__method__.to_s}" if @trace
    paths.map do |_p|
      if _p =~ %r{^/}
        _p
      else
        File.expand_path( _p, control_repo_root )
      end
    end
  end

  def tally_profiles
    warn "==== #{self.class.name}.#{__method__.to_s}" if @trace
    search_paths = full_paths(@pp_file_paths).select{|p| File.exist? p }.map{|x| File.directory?(x) ? "#{x}/" : x }
warn search_paths
    Find.find( *search_paths ) do |path|
      if File.directory?(path) && path =~ /^(.git|spec)$/
        Find.prune
      end
      next unless File.file? path
      next unless path =~ /\.pp$/
      @pp_file_subjects[path] ||= []
      classes = File.readlines(path).each do |line|
         next unless line =~ @whitelist_pattern
         @pp_types[$1] ||= []
         @pp_types[$1] << $2
         @pp_file_subjects[path] << [$1, $2]
         @pp_subject_files[$2]  ||= []
         @pp_subject_files[$2] << path
         warn "#{$1} #{$2}: #{path.sub(/^#{control_repo_root}\//,'')}" if @trace
      end
    end
  end


  # hash of profiles defined in more than one file, and their files
  def duplicate_subjects
    @pp_subject_files.select{|k,v| v.size > 1}
  end

  def multi_subject_files
    @pp_file_subjects.select{|k,v| v.size > 1}
  end

  def untested_subjects
    result = {}
    @pp_types.each do |_type,_subjects|
       if _spec_subjects = @spec_subjects.fetch(_type,nil)
         result[_type] = _subjects - _spec_subjects
       end
    end
    result
  end

  def report
    s = StringIO.new
    require 'highline'
    HighLine.colorize_strings
    unless untested_subjects.empty?
      s.puts '## Subjects that are missing tests'.bold.red
      s.puts
      untested_subjects.each do |_type,_subjects|
        s.puts "### #{_type}\n".bold.red if untested_subjects.size > 1
        s.puts '```'.gray
        _subjects.each do |x|
           s.puts x
           if @verbose
             @pp_subject_files[x].each{|f|
require 'pathname'
s.puts f.cyan }
           end
        end
        s.puts '```'.gray
      end
      s.puts
    end

    unless duplicate_subjects.empty?
      s.puts '## Duplicated subjects'.bold.white
      s.puts

      duplicate_subjects.each do |_subj,_files|
        s.puts "* `#{_subj}`".yellow
        s.puts _files.each{|f| s.puts "  - #{f.red}"}
      end
      s.puts
    end

    unless multi_subject_files.empty?
      s.puts '## Files containing multiple subjects'.bold.white
      s.puts

      multi_subject_files.each do |_file,_files|
        s.puts "* #{_file.red}"
        s.puts _files.each{|f| s.puts "  - `#{f.yellow}`"}
      end
      s.puts
    end
    s.string
  end


  def find_mismatches
    tally_profiles
    tally_spec_tests
    problems = report
    puts problems unless problems.empty?
    (require 'pry'; binding.pry) if @trace
    exit(1) unless problems.empty?
  end
end

namespace :spec do
  desc 'Find mismatched spec tests and profiles'
  task :find_mismatches do
     s = SpecTestMismatchFinder.new({
      # Must test for boolean with Rake.verbose
      :verbose => (Rake.verbose == true),
      :trace   => (Rake.application.options.trace),
     })
     s.find_mismatches

  end
end
