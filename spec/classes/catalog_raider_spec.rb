# Quick and cheap catalog debugging utility
# Save catalogs and files from catalogs
require 'spec_helper'
require 'onceover/controlrepo'

Onceover::Controlrepo.new.spec_tests do |class_name, node_name, facts, trusted_facts, trusted_external_data, pre_conditions|
  describe class_name, skip: true  do
    context "on #{node_name}" do
      let(:facts) { facts }
      let(:trusted_facts) { trusted_facts }
      let(:trusted_external_data) { trusted_external_data }
      let(:pre_condition) { pre_conditions }

      it {
        require 'yaml'
        require 'json'
        require 'fileutils'
        catalog_output_top_dir = File.join( ENV['HOME'], '_catalogs/')
        #class_node = "#{class_name.gsub(/:/,'_')}--#{node_name}"
        catalog_output_dir = File.join(catalog_output_top_dir, class_name.gsub(/:/,'_'), node_name)
        saver = Class.new do
          def initialize(dir)
            @dir = dir
          end
          def save(name, content)
            dest = File.join(@dir,name)
            FileUtils.mkdir_p(File.dirname(dest), {verbose: true})
            STDERR.puts "Writing to #{dest}"
            File.open( dest , 'w'){ |f| f.puts content }
          end
        end.new(catalog_output_dir)

        saver.save("resources.yaml", catalogue.resources.to_yaml)
        saver.save("resources.keys.json", JSON.pretty_generate(catalogue.resource_keys))
        a={}; catalogue.resource_keys.each{|x,y| a[x] ||= []; a[x] << y }
        saver.save("resources.keys.grouped.json", JSON.pretty_generate(a))
        saver.save("resources.keys.grouped.yaml", a.to_yaml)
        files_to_save = [
          '/etc/sssd/sssd.conf',
          'nsswitch.conf',
          '/etc/pam.d/password-auth',
          '/etc/pam.d/system-auth',
          '/etc/pam.d/sshd',
        ]
        files_to_save.each do |title|
          res_name = "File[#{title}]"
          res = catalogue.resource(res_name)
          if res && res[:content]
            saver.save(File.join('content', title), res[:content])
          else
            warn "WARNING: #{res_name} not found in catalog; can't save"
          end
        end
      }
    end
  end
end
