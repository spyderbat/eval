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

