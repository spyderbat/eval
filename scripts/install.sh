#!/bin/bash

SCRIPTPATH="$( cd "$(dirname -- "${BASH_SOURCE[0]}")" ; pwd -P )"
source $SCRIPTPATH/prelude.sh

# check to see if they are trying to re-install without uninstalling
if [[ "$SB_EVAL_INSTALLED" == "1" ]]; then
  echo "WARNING: running install in an already installed environment is not recommended."
  echo "Instead, run 'update.sh'. It will uninstall to clean up existing context, then re-install properly."
  if confirm "Are you sure you want to continue?" N; then
    echo "Continuing..."
  else
    exit 1
  fi
fi

function get_falco_details() {
    echo "Please enter the Spyderbat organization ID for this cluster: "
    echo "Previous value: $SPYDERBAT_ORG"
    echo -n "==> "
    read SPYDERBAT_ORG
    echo "Please enter a valid Spyderbat API key for this organization: "
    echo -n "==> "
    read SPYDERBAT_API_KEY
}

helm list -n falco | grep falco > /dev/null
if [[ $? == 1 ]]; then
  if confirm "Would you like to install the Falco integration?"; then

    if [[ (! -z "$SPYDERBAT_ORG") && (! -z "$SPYDERBAT_API_KEY") ]]; then
      cat << EOF
Previous configuration found:
  Spyderbat organization ID: $SPYDERBAT_ORG
  Spyderbat API Key: ${SPYDERBAT_API_KEY:0:3}...${SPYDERBAT_API_KEY: -3}
EOF
      if confirm "Is this correct?"; then
        echo
      else
        get_falco_details
      fi
    else
      get_falco_details
    fi

    echo "Installing..."

    helm repo add falcosecurity https://falcosecurity.github.io/charts 
    helm repo update
    helm install falco falcosecurity/falco \
      --create-namespace \
      --namespace falco \
      --set falcosidekick.enabled=true \
      --set falcosidekick.config.spyderbat.orguid="$SPYDERBAT_ORG" \
      --set falcosidekick.config.spyderbat.apiurl="${SPYDERBAT_API_URL:-https://api.spyderbat.com}" \
      --set falcosidekick.config.spyderbat.apikey="$SPYDERBAT_API_KEY" \
      --set extra.args=\{"-p","%proc.pid"\} \
      --set driver.kind=ebpf
  else
    echo "Skipping falco integration..."
  fi
else
  echo "Falco detected, not reinstalling it"
fi

echo "Running Kubectl Apply..."

kubectl apply -R -f $SCRIPTPATH/../modules

echo "The lateral movement scenario utilizes two extra cloud machines."
if confirm "Would you like to configure them now?"; then
  echo "Continuing..."
else
  echo "Not configuring lateral movement scenario."
  echo "If you would like to set it up in the future, re-run this script"
  saveconfig
  exit 0
fi

if [ -z $JUMPSERVER_IP ]; then
  cat << EOF

To continue, you will need two public-facing machines with Spyderbat installed,
and the ssh keys to access them as the given user. The install script will copy
the files necessary to run the lateral movement demo into them, including a new
ssh key and add some files in the home directory. It will also modify the bashrc,
bash history, and hostname.

Press enter to continue.

EOF
  read
else
  cat << EOF

The install script will copy the files necessary to run the lateral movement
demo into them, including a new ssh key and add some files in the home directory.
It will also modify the bashrc, bash history, and hostname.

EOF
fi

get_jumpbox_buildbox_details

echo "Setting up VMs..."
rm -f $SCRIPTPATH/buildbox_key $SCRIPTPATH/buildbox_key.pub
ssh-keygen -q -f $SCRIPTPATH/buildbox_key -N ""

# setup jumpserver
scp -i $JUMPSERVER_SSH_KEY $SCRIPTPATH/buildbox_key $JUMPSERVER_USER@$JUMPSERVER_IP:~/.ssh/buildbox_id
scp -i $JUMPSERVER_SSH_KEY -r $SCRIPTPATH/../files/jumpserver/ $JUMPSERVER_USER@$JUMPSERVER_IP:~/
ssh -i $JUMPSERVER_SSH_KEY $JUMPSERVER_USER@$JUMPSERVER_IP "mv -f jumpserver/.* .; rm -r jumpserver; echo 'ssh -i ~/.ssh/buildbox_id $BUILDBOX_USER@$BUILDBOX_IP' >> ~/.bash_history; sudo hostnamectl set-hostname jumpserver; echo 'export NICKNAME=jumpserver' >> ~/.bashrc"

# setup buildbox
BUILDBOX_AUTH_KEY=$(cat $SCRIPTPATH/buildbox_key.pub)
ssh -i $BUILDBOX_SSH_KEY $BUILDBOX_USER@$BUILDBOX_IP "echo '$BUILDBOX_AUTH_KEY' >> ~/.ssh/authorized_keys"
scp -i $BUILDBOX_SSH_KEY -r $SCRIPTPATH/../files/buildbox/ $BUILDBOX_USER@$BUILDBOX_IP:~/
ssh -i $BUILDBOX_SSH_KEY $BUILDBOX_USER@$BUILDBOX_IP "mv -f buildbox/* .;mv -f buildbox/.* .; rm -r buildbox; ssh-keygen -q -f ~/.ssh/github-login -N ''; sudo hostnamectl set-hostname buildbox; echo 'export NICKNAME=buildbox' >> ~/.bashrc"

echo
echo "Installation finished. Don't forget to install Spyderbat on these VMs if you haven't already."

SB_EVAL_INSTALLED=1

saveconfig

