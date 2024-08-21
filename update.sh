#!/bin/bash

helm list -n falco | grep falco > /dev/null
if [ $? ]; then
  echo "Falco detected; running Falco update..."

  echo -n "Please enter the Spyderbat organization ID for this cluster (empty to skip falco update): "
  read SPYDERBAT_ORG
  if [[ "$SPYDERBAT_ORG" != "" ]]; then
    echo -n "Please enter a valid Spyderbat API key for this organization: "
    read SPYDERBAT_API_KEY

    helm upgrade falco falcosecurity/falco \
      --create-namespace \
      --namespace falco \
      --set falcosidekick.enabled=true \
      --set falcosidekick.config.spyderbat.orguid="$SPYDERBAT_ORG" \
      --set falcosidekick.config.spyderbat.apiurl="${SPYDERBAT_API_URL:-https://api.spyderbat.com}" \
      --set falcosidekick.config.spyderbat.apikey="$SPYDERBAT_API_KEY" \
      --set extra.args=\{"-p","%proc.pid"\} \
      --set driver.kind=modern_ebpf
  fi
else
  echo "Falco not detected; skipping Falco update..."
fi

echo "Running kubectl; if this breaks, try deleting the trouble resources and re-running..."
kubectl delete pod -n build bobdev
kubectl apply -R -f modules --prune -l managed-by=spyderbat-eval
# restart the deployments to re-pull the image
kubectl rollout restart deployment --selector=managed-by=spyderbat-eval
kubectl rollout restart deployment --namespace guidebook --selector=managed-by=spyderbat-eval
kubectl rollout restart deployment --namespace supply-chain --selector=managed-by=spyderbat-eval
kubectl rollout restart deployment --namespace lateral-movement --selector=managed-by=spyderbat-eval
kubectl rollout restart deployment --namespace cryptominer --selector=managed-by=spyderbat-eval
kubectl rollout restart deployment --namespace payroll-prod --selector=managed-by=spyderbat-eval

