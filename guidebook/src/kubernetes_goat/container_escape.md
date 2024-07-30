# Container Escape to the Host System

## Pre-Requisites

Make sure the cluster is running and your Kubectl configuration is set up to access the cluster. If not, follow [these steps](../getting-started.md) to get started.

## Running the Exploit

Follow the guide [in the Kubernetes Goat documentation](https://madhuakula.com/kubernetes-goat/docs/scenarios/scenario-4/container-escape-to-the-host-system-in-kubernetes-containers/welcome).

## Investigating the Results

Performing this exploit will trigger a number of red flags which are detected and collected into a single Spydertrace object. In the Spyderbat Console, navigate to the Dashboard page. In the Security tab, under "Recent Spydertraces with Score > 50", a new trace should appear highlighting the exploit commands. Selecting this Spydertrace, we can select "Start Process Investigation" to see the events of the exploit layed out in a Causal Tree in the investigation view.

## Next Steps

[[TODO]]
