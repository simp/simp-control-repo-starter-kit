#!/bin/bash
# ------------------------------------------------------------------------------
# NOTE: This file is managed by Puppet.  Do not edit it on the server.
# ------------------------------------------------------------------------------
# Safely deploy r10k with correct group ownership (saves time from `chown -R`)
# ------------------------------------------------------------------------------

R10K_EXE="/usr/share/simp/bin/r10k"
R10K_DEPLOY="$R10K_EXE deploy environment -v info --puppetfile"
PUPPET_ENVIRONMENTS_DIR='/etc/puppetlabs/code/environments'
PUPPET_ENVIRONMENT="$1"

if [ -z "$1" ] ; then
  $R10K_EXE
  exit;
fi

# 0007 = new files are group read/writeable (by r10k/puppet)
( umask 0007 && sg puppet -c "$R10K_DEPLOY $PUPPET_ENVIRONMENT" )

if [ $? == '1' ] ; then
  echo 'Exiting, please use valid environment name.'
  exit;
fi

if [ $UID == 0 ]; then
  # correct SELinux contexts
  chcon -R --reference="$PUPPET_ENVIRONMENTS_DIR" "$PUPPET_ENVIRONMENTS_DIR/$1"
fi

