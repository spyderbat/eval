#!/bin/bash

SCRIPTPATH="$( cd "$(dirname -- "${BASH_SOURCE[0]}")" ; pwd -P )"
source $SCRIPTPATH/prelude.sh

echo "Starting port forwarding..."

# Cryptominer Scenario
export POD_NAME=$(kubectl get pods --namespace cryptominer -l "app=jupyter-notebook" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace cryptominer $POD_NAME --address 0.0.0.0 1234:8888 > /dev/null 2>&1 &

# guidebook
export POD_NAME=$(kubectl get pods --namespace guidebook -l "app=guidebook" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace guidebook $POD_NAME --address 0.0.0.0 8800:3000 > /dev/null 2>&1 &

echo "Visit http://localhost:8800 to get started"
echo "Press Ctrl-C to quit"

wait
