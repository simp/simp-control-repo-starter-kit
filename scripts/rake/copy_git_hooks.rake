desc "Installs git hooks into local repository

Currently this is a pre-commit hook for `rake validate` (Puppetfile lint)"
task :copy_git_hooks do
    puts "Adding in git hooks"
    FileUtils.cp_r Dir.glob('scripts/hooks/*'), '.git/hooks/'
    FileUtils.chmod_R(0755,'.git/hooks/')
end

