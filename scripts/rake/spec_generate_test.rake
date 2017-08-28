require 'erb'
require 'fileutils'
require 'highline'

class SpecTestFileGenerator
  def initialize
    @template_path = File.expand_path("templates", File.dirname(__FILE__))
    @spec_path = File.expand_path('../../../spec',@template_path)
  end

  def scaffold_files(subject,type)
    dirs = {
      'class' => 'classes',
      'define' => 'defines',
    }
    template = File.read(File.join(@template_path,"spec_#{type}.erb"))
    puppet_class = subject
    content = ERB.new(template).result(binding)
    _name_dirs = File.join(subject.split('::').map{|x| x.downcase}) + '_spec.rb'
    _dir = dirs[type]
    _file = File.join(@spec_path, _dir, _name_dirs )
    if File.exists? _file
      warn "ERROR: File already exists at '#{_file}'!".red
      exit(1)
    else
      FileUtils.mkdir_p(File.dirname(_file))
      File.write(_file, content)
      puts "Wrote tests for #{type.bold} #{subject.bold} to #{_file}".green
    end
  end
end

namespace :spec do
  task :generate_test, [:subject,:type] do |t,args|
    args.with_defaults(:type =>'class')
    s = SpecTestFileGenerator.new
    s.scaffold_files(args[:subject],args[:type])

  end
end