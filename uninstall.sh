#!/bin/bash

function confirm() {
  echo -n $1 "[Y/n]: "
  read ANSWER
  if [[ ! ( "${ANSWER:0:1}" == "y" || "${ANSWER:0:1}" == "Y" || "${ANSWER:0:1}" == "" ) ]]; then
    return 1
  else
    return 0
  fi
}

if [ ! -x "$(command -v kubectl)" ]; then
  echo "Kubectl not installed. Visit https://kubernetes.io/docs/tasks/tools/ to install it."
  exit 1
fi

CONTEXT=$(kubectl config current-context)

if [ $? -ne 0 ]; then
  echo "No current kubectl context found. Please configure kubectl with access to the cluster you want to install on."
  exit 1
fi

cat << EOF
== Spyderbat Evaluation Samples Uninstaller ==

Installing into the kubectl context: $CONTEXT
EOF
if confirm "Is this correct?"; then
  # continue
else
  echo "Cancelling..."
  echo "Set the kubectl context to the desired context then re-run this script."
  exit 1
fi

kubectl delete namespaces -l=managed-by=spyderbat-eval
helm list -n falco | grep falco > /dev/null
if [ $? ]; then
  echo -n "Falco detected; would you like to uninstall Falco? [y/N]: "
  read answer
  if [[ "${answer:0:1}" == "y" || "${answer:0:1}" == "Y" ]]; then
    echo "Uninstalling Falco"
    helm uninstall -n falco falco
  else
    echo "Not uninstalling Falco"
    return 0
  fi
fi

if confirm "Would you like to uninstall from the two extra cloud servers?"; then
  echo "Continuing..."
else
  echo "Not uninstalling from the two extra cloud servers."
  echo "If you would like to uninstall in the future, re-run this script"
  exit 0
fi

cat << EOF

To continue, you will need the credentials to access the machines already set up
in the install script. This will remove the files installed by the install script
and uninstall netcat, but will not remove the public key from the buildbox
authorized_keys and will not change the bash history.
Press enter to continue.

EOF
read

echo -n "Please enter the public IP address of the machine to set up as the jumpserver: "
read JUMPSERVER_IP
echo -n "Please enter the username for the machine to set up as the jumpserver: "
read JUMPSERVER_USER
echo -n "Please enter the path to the ssh key to access the jumpserver: "
read JUMPSERVER_SSH_KEY
echo -n "Please enter the public IP address of the machine to set up as the buildbox: "
read BUILDBOX_IP
echo -n "Please enter the username for the machine to set up as the buildbox: "
read BUILDBOX_USER
echo -n "Please enter the path to the ssh key to access the buildbox: "
read BUILDBOX_SSH_KEY

cat << EOF
Using:
jumpserver: $JUMPSERVER_USER@$JUMPSERVER_IP
  - identity: $JUMPSERVER_SSH_KEY
buildbox: $BUILDBOX_USER@$BUILDBOX_IP
  - identity: $BUILDBOX_SSH_KEY
EOF

if confirm "Is this correct?"; then
  echo "Continuing..."
else
  echo "Cancelling..."
  echo "Re-run the script to enter the correct information"
  exit 1
fi

ssh-keygen -q -f buildbox_key -N ""

# jumpserver
ssh -i $JUMPSERVER_SSH_KEY $JUMPSERVER_USER@$JUMPSERVER_IP "rm .ssh/buildbox_id"

# buildbox
ssh -i $BUILDBOX_SSH_KEY $BUILDBOX_USER@$BUILDBOX_IP "rm .ssh/github-login; rm -r payroll-app"

echo
echo "Uninstall finished"
