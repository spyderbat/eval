#!/bin/bash

#
# Utils: a set of commonly used functions
#

# Usage:
# if confirm "Are you sure?"; then
#   # do the thing
# fi
function confirm() {
  prompt=$1
  default=$2

  case "$default" in 
    y|Y|"" ) default=0;prompt="$prompt [Y/n]: ";;
    n|N ) default=1;prompt="$prompt [y/N]: ";;
    * ) echo "There is a bug in the script, quitting!";exit 1;;
  esac

  while [ 1 ]; do

    printf "\033[0;1m$prompt\033[0m"
    read choice

    case "${choice:0:1}" in 
      y|Y ) return 0;;
      n|N ) return 1;;
      "" ) return $default;;
      * ) echo "Invalid response, please enter y or n";;
    esac

  done
}

# reads in an environment file if present
function readconfig() {
  SCRIPTPATH="$( cd "$(dirname -- "${BASH_SOURCE[0]}")" ; pwd -P )"
  if [ -f "$SCRIPTPATH/.config" ]; then
    set -a
    source "$SCRIPTPATH/.config"
    set +a
  fi
}

# saves the config to an environment file
function saveconfig() {
  SCRIPTPATH="$( cd "$(dirname -- "${BASH_SOURCE[0]}")" ; pwd -P )"
  cat << EOF > "$SCRIPTPATH/.config"
SB_EVAL_INSTALLED=$SB_EVAL_INSTALLED

KUBECTL_CONTEXT=$KUBECTL_CONTEXT
SPYDERBAT_ORG=$SPYDERBAT_ORG
SPYDERBAT_API_KEY=$SPYDERBAT_API_KEY

VMS_SET=$VMS_SET
JUMPSERVER_IP=$JUMPSERVER_IP
JUMPSERVER_USER=$JUMPSERVER_USER
JUMPSERVER_SSH_KEY=$JUMPSERVER_SSH_KEY

BUILDBOX_IP=$BUILDBOX_IP
BUILDBOX_USER=$BUILDBOX_USER
BUILDBOX_SSH_KEY=$BUILDBOX_SSH_KEY
EOF
  chmod 0600 "$SCRIPTPATH/.config"
}

function get_jumpbox_buildbox_details() {
  while true; do
    if [ -z "$VMS_SET" ]; then
      echo test | read -p "==> " -i "test" -e TEST_VAR > /dev/null 2>&1
      if [[ $? != 0 ]]; then
        # we can't use fancy read features
        echo "Please enter the public IP address of the machine to set up as the jumpserver: "
        echo "Previous value: $JUMPSERVER_IP"
        echo -n "==> "
        read JUMPSERVER_IP
        echo "Please enter the username for the machine to set up as the jumpserver: "
        echo "Previous value: $JUMPSERVER_USER"
        echo -n "==> "
        read JUMPSERVER_USER
        echo "Please enter the path to the ssh key to access the jumpserver: "
        echo "Previous value: $JUMPSERVER_SSH_KEY"
        echo -n "==> "
        read JUMPSERVER_SSH_KEY
        echo "Please enter the public IP address of the machine to set up as the buildbox: "
        echo "Previous value: $BUILDBOX_IP"
        echo -n "==> "
        read BUILDBOX_IP
        echo "Please enter the username for the machine to set up as the buildbox: "
        echo "Previous value: ${BUILDBOX_USER:-$JUMPSERVER_USER}"
        echo -n "==> "
        read BUILDBOX_USER
        echo "Please enter the path to the ssh key to access the buildbox: "
        echo "Previous value: ${BUILDBOX_SSH_KEY:-$JUMPSERVER_SSH_KEY}"
        echo -n "==> "
        read BUILDBOX_SSH_KEY
      else
        echo "Please enter the public IP address of the machine to set up as the jumpserver: "
        read -p "==> " -e -i "$JUMPSERVER_IP" JUMPSERVER_IP
        echo "Please enter the username for the machine to set up as the jumpserver: "
        read -p "==> " -e -i "$JUMPSERVER_USER" JUMPSERVER_USER
        echo "Please enter the path to the ssh key to access the jumpserver: "
        read -p "==> " -e -i "$JUMPSERVER_SSH_KEY" JUMPSERVER_SSH_KEY
        echo "Please enter the public IP address of the machine to set up as the buildbox: "
        read -p "==> " -e -i "$BUILDBOX_IP" BUILDBOX_IP
        echo "Please enter the username for the machine to set up as the buildbox: "
        read -p "==> " -e -i "${BUILDBOX_USER:-$JUMPSERVER_USER}" BUILDBOX_USER
        echo "Please enter the path to the ssh key to access the buildbox: "
        read -p "==> " -e -i "${BUILDBOX_SSH_KEY:-$JUMPSERVER_SSH_KEY}" BUILDBOX_SSH_KEY
      fi
      export VMS_SET=1
    fi

    cat << EOF
Using:
jumpserver: $JUMPSERVER_USER@$JUMPSERVER_IP
  - identity: $JUMPSERVER_SSH_KEY
buildbox: $BUILDBOX_USER@$BUILDBOX_IP
  - identity: $BUILDBOX_SSH_KEY
EOF

    if confirm "Is this correct?"; then
      break
    else
      VMS_SET=""
    fi
  done
}

