require 'spec_helper'

describe 'profile::base' do
  environments.each do |env_name|
    context "in environment '#{env_name}'" do
      factsets.each do |fs_name,fs_facts|
        context "on #{fs_name} (derived from #{fs_facts['clientcert']})" do
          let(:facts){ fs_facts }
          let(:environment){ env_name }
          let(:pre_condition){ 'lookup("simp_options::trusted_nets")' }
          context "without a ::role" do
            it do
              require 'pry'; binding.pry
              is_expected.to compile.with_all_deps
            end
          end
        end
      end
    end
  end
end

