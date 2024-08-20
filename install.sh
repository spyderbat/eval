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
== Spyderbat Evaluation Samples Installer ==

Installing into the kubectl context: $CONTEXT
EOF

if confirm "Would you like to install the Falco integration?"; then
  echo -n "Please enter the Spyderbat organization ID for this cluster: "
  read SPYDERBAT_ORG
  echo -n "Please enter a valid Spyderbat API key for this organization: "
  read SPYDERBAT_API_KEY

  helm install falco falcosecurity/falco \
    --create-namespace \
    --namespace falco \
    --set falcosidekick.enabled=true \
    --set falcosidekick.config.spyderbat.orguid="$SPYDERBAT_ORG" \
    --set falcosidekick.config.spyderbat.apiurl="${SPYDERBAT_API_URL:-https://api.spyderbat.com}" \
    --set falcosidekick.config.spyderbat.apikey="$SPYDERBAT_API_KEY" \
    --set extra.args=\{"-p","%proc.pid"\} \
    --set driver.kind=modern_ebpf
else
  echo "Skipping falco integration..."
fi

kubectl apply -R -f modules

echo "The lateral movement scenario utilizes two extra cloud machines."
if confirm "Would you like to configure them now?"; then
  echo "Continuing..."
else
  echo "Not configuring lateral movement scenario."
  echo "If you would like to set it up in the future, re-run this script"
  exit 0
fi

cat << EOF

To continue, you will need two public-facing machines, and the ssh keys
to access them as the root user. The install script will copy the files
necessary to run the lateral movement demo into them, including a new
ssh key, modifying the hosts file, and some files in the /root directory.
Press enter to continue.

EOF
read

echo -n "Please enter the public IP address of the machine to set up as the jumpserver: "
read JUMPSERVER_IP
echo -n "Please enter the path to the ssh key to access the jumpserver: "
read JUMPSERVER_SSH_KEY
echo -n "Please enter the public IP address of the machine to set up as the buildbox: "
read BUILDBOX_IP
echo -n "Please enter the path to the ssh key to access the buildbox: "
read BUILDBOX_SSH_KEY

cat << EOF
Using:
jumpserver: root@$JUMPSERVER_IP
  - identity: $JUMPSERVER_SSH_KEY
buildbox: root@$BUILDBOX_IP
  - identity: $BUILDBOX_SSH_KEY
EOF

if confirm "Is this correct?"; then
  echo "Continuing..."
else
  echo "Cancelling..."
  exit 1
fi

ssh-keygen -q -f buildbox_key -N ""

# setup jumpserver
scp -i $JUMPSERVER_SSH_KEY buildbox_key root@$JUMPSERVER_IP:~/.ssh/buildbox_id
ssh -i $JUMPSERVER_SSH_KEY root@$JUMPSERVER_IP "echo 'echo \"$BUILDBOX_IP buildbox\" >> /etc/hosts' >> ~/.bashrc"
scp -i $JUMPSERVER_SSH_KEY -r files/jumpserver/ root@$JUMPSERVER_IP:~/
ssh -i $JUMPSERVER_SSH_KEY root@$JUMPSERVER_IP "mv jumpserver/.* .; rmdir jumpserver"

# setup buildbox
BUILDBOX_AUTH_KEY=$(cat buildbox_key.pub)
ssh -i $BUILDBOX_SSH_KEY root@$BUILDBOX_IP "echo '$BUILDBOX_AUTH_KEY' >> ~/.ssh/authorized_keys"
scp -i $BUILDBOX_SSH_KEY -r files/buildbox/ root@$BUILDBOX_IP:~/
ssh -i $BUILDBOX_SSH_KEY root@$BUILDBOX_IP "mv buildbox/* .;mv buildbox/.* .; rmdir buildbox; touch ~/.ssh/github-login"

