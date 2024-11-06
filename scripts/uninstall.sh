#!/bin/bash

SCRIPTPATH="$( cd "$(dirname -- "${BASH_SOURCE[0]}")" ; pwd -P )"
source $SCRIPTPATH/prelude.sh

echo "Uninstalling all spyderbat-eval managed namespaces; this may take some time."
kubectl delete namespaces -l=managed-by=spyderbat-eval

helm list -n falco | grep falco > /dev/null
if [[ $? == 0 ]]; then
  if confirm "Falco detected; would you like to uninstall Falco?" N; then
    echo "Uninstalling Falco"
    helm uninstall -n falco falco
  else
    echo "Not uninstalling Falco"
  fi
fi

if confirm "Would you like to uninstall from the two extra cloud servers?" N; then
  echo "Continuing..."
else
  echo "Not uninstalling from the two extra cloud servers."
  echo "If you would like to uninstall in the future, re-run this script"
  saveconfig
  exit 0
fi

if [ -z $JUMPSERVER_IP ]; then
  cat << EOF

To continue, you will need the credentials to access the machines already set up
in the install script. This script will remove the files installed by the install
script, uninstall netcat, and remove the backdoor users. To prevent breaking access
to the machine, it will not remove the generated public key from the buildbox
authorized_keys, delete the bash history, reset the bashrc, reset the hostname, or
reset the sudoers file.

Press enter to continue.

EOF
  read
else
  cat << EOF

This script will remove the files installed by the install
script, uninstall netcat, and remove the backdoor users. To prevent breaking access
to the machine, it will not remove the generated public key from the buildbox
authorized_keys, delete the bash history, reset the bashrc, reset the hostname, or
reset the sudoers file.

EOF
fi

get_jumpbox_buildbox_details

echo "Cleaning up VMs..."

# jumpserver
ssh -i $JUMPSERVER_SSH_KEY $JUMPSERVER_USER@$JUMPSERVER_IP "rm -rf .ssh/buildbox_id; sudo userdel -rf backdoor"

# buildbox
ssh -i $BUILDBOX_SSH_KEY $BUILDBOX_USER@$BUILDBOX_IP 'rm -rf ~/.ssh/github-login ~/payroll-app; if [ -x "$(command -v yum)" ]; then sudo yum remove nmap-ncat -yq; else sudo apt remove ncat; fi; sudo userdel -rf backdoor; sudo killall -9 nc'

echo
echo "Uninstall finished"

SB_EVAL_INSTALLED=0

saveconfig

