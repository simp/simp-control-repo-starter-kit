#
class role::puppetserver {
  include profile::base
  include profile::puppetserver::r10k
  include profile::puppetserver::deploy_hook
}
