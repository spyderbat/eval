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

if [[ -z "$KUBECTL_CONTEXT" || "$KUBECTL_CONTEXT" != "$(kubectl config current-context)" ]]; then
  if [ ! -x "$(command -v kubectl)" ]; then
    echo "Kubectl not installed. Visit https://kubernetes.io/docs/tasks/tools/ to install it."
    exit 1
  fi

  export KUBECTL_CONTEXT=$(kubectl config current-context)

  if [ $? -ne 0 ]; then
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

