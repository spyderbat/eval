#!/bin/bash

# 
# Prelude: a set of checks and setup that are run before every script.
# Also imports the utils script.
#

if [ -z "$PRINTED_PRELUDE" ]; then
  export PRINTED_PRELUDE=1
  cat << EOF
=== Spyderbat Eval Samples Manager ===

EOF
fi

SCRIPTPATH="$( cd "$(dirname -- "${BASH_SOURCE[0]}")" ; pwd -P )"
source $SCRIPTPATH/utils.sh

readconfig

# ensure that the necessary programs are available
if [ ! -x "$(command -v kubectl)" ]; then
  echo "Kubectl not installed. Visit https://kubernetes.io/docs/tasks/tools/ to install it."
  exit 1
fi
if [ ! -x "$(command -v helm)" ]; then
  echo "Helm not installed. Visit https://helm.sh/docs/intro/install/ to install it."
  exit 1
fi

if [[ -z "$KUBECTL_CONTEXT" || "$KUBECTL_CONTEXT" != "$(kubectl config current-context 2> /dev/null)" ]]; then

  export KUBECTL_CONTEXT=$(kubectl config current-context)

  if [ -z "$KUBECTL_CONTEXT" ]; then
    echo "No current kubectl context found. Please configure kubectl with access to the cluster you want to install on."
    exit 1
  fi

  echo "Using the kubectl context: $KUBECTL_CONTEXT"
  if confirm "Is this correct?"; then
    echo
  else
    echo "Cancelling..."
    echo "Please set the kubectl context to the desired install context then re-run this script."
    exit 1
  fi
else
  echo "Using the kubectl context: $KUBECTL_CONTEXT"
fi

# test the connection with the cluster
kubectl get pods > /dev/null
if [ $? -ne 0 ]; then
  echo
  ping -c 1 google.com > /dev/null
  if [ $? -ne 0 ]; then
    echo
    echo "Connection to the network failed (checking google.com); is your internet working?"
    exit 1
  else
    echo
    echo "You have internet, but connection to your cluster failed; are you behind a proxy?"
    exit 1
  fi
fi

