#!/bin/bash

kubectl delete namespaces -l=managed-by=spyderbat-eval
helm list -n falco | grep falco > /dev/null
if [ $? ]; then
  echo -n "Falco detected; would you like to uninstall Falco? (only 'yes' will be accepted) "
  read answer
  if [ "$answer" == "yes" ]; then
    helm uninstall -n falco falco
  else
    echo "Not uninstalling Falco"
  fi
fi

