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

if [ -x "$(command -v jq)" ]; then
  if [ -x "$(command -v spyctl)" ]; then
    SPYCTL_CONTEXT=$(spyctl config current-context)

    if [ $? -ne 0 ]; then
      echo "No current spyctl context found. Please configure spyctl with access to the Spyderbat organization that the cluster is on."
      exit 1
    fi
  fi
fi

cat << EOF
== Spyderbat Evaluation Samples Installer ==

Installing into the kubectl context: $CONTEXT
EOF

if [ ! ( -x "$(command -v jq)" && -x "$(command -v spyctl)" ) ]; then
  echo -n "Please enter the Spyderbat organization ID for this cluster: "
  read SPYDERBAT_ORG
  echo -n "Please enter a valid Spyderbat API key for this organization: "
  read SPYDERBAT_API_KEY
else
  echo "Installing into the spyctl context: $SPYCTL_CONTEXT"
  SPYDERBAT_ORG=$(spyctl config view -o json | jq -r '.contexts | select(.[].name="'$(spyctl config current-context)'") | .[0].context.organization')
  SPYCTL_SECRET=$(spyctl config view -o json | jq -r '.contexts | select(.[].name="'$(spyctl config current-context)'") | .[0].secret')
  SPYDERBAT_API_KEY=$(spyctl config get-apisecrets "$SPYCTL_SECRET" -o json | jq -r .stringData.apikey)
fi

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

kubectl apply -R -f modules

