#!/bin/bash

if [ ! -x "$(command -v kubectl)" ]; then
  echo "Kubectl not installed. Visit https://kubernetes.io/docs/tasks/tools/ to install it."
  exit 1
fi

CONTEXT=$(kubectl config current-context)

if [ $? -ne 0 ]; then
  echo "No current kubectl context found. Please configure kubectl with access to the cluster you want to install on."
  exit 1
fi

# Container Escape Scenario, from k8s Goat
export POD_NAME=$(kubectl get pods -l "app=system-monitor" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME --address 0.0.0.0 1233:8080 > /dev/null 2>&1 &

# Cryptominer Scenario
export POD_NAME=$(kubectl get pods --namespace cryptominer -l "app=jupyter-notebook" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace cryptominer $POD_NAME --address 0.0.0.0 1234:8888 > /dev/null 2>&1 &

export POD_NAME=$(kubectl get pods --namespace guidebook -l "app=guidebook" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace guidebook $POD_NAME --address 0.0.0.0 8000:3000 > /dev/null 2>&1 &

echo "Port forwarding started"
echo "Visit http://localhost:8000 to get started"
echo "Press Ctrl-C to quit"

wait
