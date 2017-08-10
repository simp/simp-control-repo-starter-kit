require 'spec_helper'

describe 'profile::base' do
  matrix do |fs_facts, fs_name, env_name|
    context "without a ::role" do
      it do
        is_expected.to compile.with_all_deps
      end
    end
  end
end

