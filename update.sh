#!/bin/sh

if [ ! -x "$(command -v jq)" ]; then
  echo "The jq command was not found, please install it"
  exit 1
fi

SPYDERBAT_ORG=$(spyctl config view -o json | jq -r '.contexts | select(.[].name="'$(spyctl config current-context)'") | .[0].context.organization')
SPYCTL_SECRET=$(spyctl config view -o json | jq -r '.contexts | select(.[].name="'$(spyctl config current-context)'") | .[0].secret')
SPYDERBAT_API_KEY=$(spyctl config get-apisecrets "$SPYCTL_SECRET" -o json | jq -r .stringData.apikey)

helm list -n falco | grep falco > /dev/null
if $?; then
  OPERATION=install
else
  OPERATION=update
fi

helm $OPERATION falco . \
  --create-namespace \
  --namespace falco \
  --set falcosidekick.enabled=true \
  --set falcosidekick.config.spyderbat.orguid="$SPYDERBAT_ORG" \
  --set falcosidekick.config.spyderbat.apiurl="${SPYDERBAT_API_URL:-https://api.spyderbat.com}" \
  --set falcosidekick.config.spyderbat.apikey="$SPYDERBAT_API_KEY"

kubectl apply -R -f modules --prune -l managed-by=spyderbat-eval
# restart the deployments to restart the pods
kubectl rollout restart deployment --selector=managed-by=spyderbat-eval
kubectl rollout restart deployment --namespace guidebook --selector=managed-by=spyderbat-eval
kubectl rollout restart deployment --namespace supply-chain --selector=managed-by=spyderbat-eval

