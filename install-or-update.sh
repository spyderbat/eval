#!/bin/sh

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

Installing into the context: $CONTEXT
EOF

kubectl apply -R -f modules --prune -l managed-by=spyderbat-eval
# restart the deployments to restart the pods
kubectl rollout restart deployment --selector=managed-by=spyderbat-eval
kubectl rollout restart deployment --namespace guidebook --selector=managed-by=spyderbat-eval
kubectl rollout restart deployment --namespace supply-chain --selector=managed-by=spyderbat-eval
