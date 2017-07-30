namespace :puppetfile do
	desc "Syntax check Puppetfile"
	task :syntax do
		require 'r10k/action/puppetfile/check'

		puppetfile = R10K::Action::Puppetfile::Check.new({
			:root => ".",
			:moduledir => nil,
			:puppetfile => nil
		}, '')
    puts '---> puppetfile:syntax'
    unless puppetfile.call
			fail 'Puppetfile syntax check failed'
		end
	end
end

# Add puppetfile:syntax to :syntax checks
task :syntax => 'puppetfile:syntax'
