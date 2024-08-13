# Contributing

## Setup

### Guide Book

[Install mdBook](https://rust-lang.github.io/mdBook/guide/installation.html).

See [the guide](https://rust-lang.github.io/mdBook/) to learn how mdBook works.

### Helm

[Install Helm](https://helm.sh/docs/intro/install/).

## Local Testing

When working on the guidebook, run `mdbook` in the book directory to get a live-updating hosted version of the book:

```sh
mdbook serve --open
```

The book image can be built from the book directory with:

```sh
docker build . -t spyderbat/eval-guidebook:vX.X.X
```

When installing the Helm chart on a cluster, the Docker image needs to be available for the cluster to pull. In a local development environment using minikube, this can be dony by enabling the minikube Docker context before building:

```sh
eval $(minikube docker-env)
```

After this, the helm chart can be installed from the root directory using:

```sh
helm install RELEASE_NAME ./spyderbat-eval
```

With the Helm install completed, you can get access to the documentation using a kubectl forwarding rule:

```sh
POD_NAME=$(kubectl get pods -o json | jq -r '.items[].metadata.name' | grep guidebook)
kubectl port-forward $POD_NAME --address 0.0.0.0 8000:3000
```

## Adding a Scenario

1. Start mdBook in the `guidebook` directory (`mdbook serve --open` or use `make serve`)
2. Add an entry in [the SUMMARY file](./guidebook/src/SUMMARY.md) for your new scenario, and save the file. mdBook will automatically create a new file for you
3. Fill out the scenario entry. The page will be updated live by mdBook every time you save.
4. Add any new modules to the `modules` directory, if necessary. **Make sure to add the label `managed-by: spyderbat-eval` to all resources to ensure they are detected when updating.**
5. Update `./access.sh` with any new port-forward commands needed to access resources for the scenario.
6. Update `./install.sh` and `./update.sh` with any new commands needed to create or update resources.

### Publishing the Updates

1. Update the guidebook image by running `make update-image` in the `guidebook` directory
2. Run the `./update.sh` script with any clusters that need updating

