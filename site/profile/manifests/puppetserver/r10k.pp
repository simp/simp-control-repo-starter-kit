#
class profile::puppetserver::r10k(
  Hash $config,
  Stdlib::Absolutepath $config_path = '/etc/puppetlabs/r10k/r10k.yaml',
  Stdlib::Absolutepath $helper_path = '/usr/local/sbin/r10k_deploy.sh',
){
  file{ '/etc/puppetlabs/r10k':
    mode    => '0750',
    owner   => root,
    group   => puppet,
    seltype => 'puppet_etc_t',
  }

  file{ $config_path:
    content => $config.to_yaml,
    mode    => '0640',
    owner   => root,
    group   => puppet,
    seltype => 'puppet_etc_t',
  }

  file{ $helper_path:
    mode   => '0750',
    owner  => root,
    group  => puppet,
    source => 'puppet:///modules/profile/puppetserver/r10k_deploy.sh',
  }

  file{ '/usr/local/sbin/r10_deploy.sh':
    ensure =>  absent,
  }
}
