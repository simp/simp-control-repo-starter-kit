require 'puppetlabs_spec_helper/rake_tasks'
require 'metadata-json-lint/rake_task'
require 'rake/clean'

MetadataJsonLint.options.strict_license = false

# Load extra rake tasks if any exist
Dir.glob('scripts/rake/*.rake').each { |r| load r}
