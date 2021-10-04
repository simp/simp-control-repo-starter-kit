#
class profile::puppetserver::deploy_hook(
  String[1] $svc_account_user = 'puppet-deploy',
  Stdlib::Absolutepath $svc_account_homedir = "/home/${svc_account_user}",
  String[1]            $svc_account_ssh_public_key,
  String[1]            $svc_account_ssh_private_key,
  Integer              $svc_account_uid     = 303,
  String[1]            $svc_account_group   = 'puppet',

  # permit the account to scp files and mkdir -p under /var/ISO/CI
  String $ssh_cmd_regex ='^/usr/local/sbin/r10k_deploy.sh',
  String $ssh_auth_restrictions = 'no-port-forwarding,no-pty',
  String $ssh_cmd_start = 'command="if [[ \"$SSH_ORIGINAL_COMMAND\" =~ ',
  String $ssh_cmd_end   = ']]; then $SSH_ORIGINAL_COMMAND ; else echo Access Denied; fi"',
  String[1] $ssh_cmd    = "${ssh_cmd_start} ${ssh_cmd_regex} ${ssh_cmd_end}",
){
  # Since this is a service account, automatically generate an SSH key for
  # the user and store it on the Puppet master for distribution.

  file {  $svc_account_homedir:
    ensure => directory,
    owner  => $svc_account_user,
    group  => $svc_account_group,
    mode   =>  '0755',
  }

  -> file {  "${svc_account_homedir}/.ssh":
    ensure => directory,
    owner  => $svc_account_user,
    group  => $svc_account_group,
    mode   =>  '0700',
  }

  -> file { "${svc_account_homedir}/.ssh/id_rsa":
    content => $svc_account_ssh_private_key,
    owner   => $svc_account_user,
    group   => $svc_account_group,
    mode    =>  '0600',
  }


  user{ $svc_account_user:
    ensure     => present,
    uid        => $svc_account_uid,
    allowdupe  => false,
    gid        => $svc_account_group,
    home       => $svc_account_homedir,
    managehome => true,
    shell      => '/bin/bash',
  }

  # Allow this service account from everywhere
  pam::access::rule { "Allow ${svc_account_user}":
    users   => [$svc_account_user],
    origins => ['ALL'],
  }

  # SIMP sshd (by default) keeps authorized_keys under /etc/ssh/local_keys/
  file { "/etc/ssh/local_keys/${svc_account_user}":
    owner   => 'root',
    group   => $svc_account_group,
    mode    => '0644',
    content => "${ssh_auth_restrictions},${ssh_cmd} ssh-rsa ${svc_account_ssh_public_key}",
  }
}
