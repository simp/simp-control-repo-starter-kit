#!/bin/bash
# ------------------------------------------------------------------------------
# NOTE: This file is managed by Puppet.  Do not edit it on the server.
# ------------------------------------------------------------------------------
# Safely deploy r10k with correct group ownership (saves time from `chown -R`)
# ------------------------------------------------------------------------------

R10K_EXE="/usr/share/simp/bin/r10k"
R10K_DEPLOY="$R10K_EXE deploy environment -v info --puppetfile"
PUPPET_ENVIRONMENTS_DIR='/etc/puppetlabs/code/environments'
ENV2D=$1

if [ -z $1 ] ; then
  $R10K_EXE
  exit;
fi

# 0007 group should be puppet
( umask 0007 && sg puppet -c "$R10K_DEPLOY $ENV2D" )

if [ $UID == 0 ]; then
  chcon -R --reference="$PUPPET_ENVIRONMENTS_DIR" "$PUPPET_ENVIRONMENTS_DIR/$1"           # correct SELinux contexts
fi

if [ $? == '1' ] ; then
  echo 'Exiting, please use valid environment name.'
  exit;
fi
