# Lint & Syntax exclusions
exclude_paths = [
  'bundle/**/*',
  'pkg/**/*',
  'dist/**/*',
  'vendor/**/*',
  '.vendor/**/*',
  'spec/**/*',
  '.onceover/**/*',
  'modules/**/*', # This is a control repo; modules are tested in their own repos
]

def rakefile_require(r)
  begin
    return require(r)
  rescue LoadError => e
    warn "Rakefile: #{e}"
  end
end

rakefile_require 'onceover/rake_tasks'

if rakefile_require('puppet-lint/tasks/puppet-lint')
  PuppetLint.configuration.ignore_paths = exclude_paths
end


if rakefile_require 'puppet-syntax/tasks/puppet-syntax'
  PuppetSyntax.exclude_paths = exclude_paths
  PuppetSyntax.hieradata_paths = ['data/**/*.yaml']
  PuppetSyntax.fail_on_deprecation_notices = false # FIXME: unset before production!
end
