# Spyderbat Evaluation Environment

A set of tools for evaluating and showcasing the features offered by Spyderbat.

## Getting Started

### Pre-requisites

<details>
    <summary>A Kubernetes cluster</summary>

You will need a Kubernetes cluster in the cloud or locally that can be used for the demos. Several demos include running realistic exploits against this cluster, so it should not contain any sensitive applications. Each node should have around 32 GB of storage to have enough space for the images that will be installed. Multiple nodes are recommended, but not required.

</details>

<details>
    <summary>Kubectl and Helm</summary>

To install the evaluation environment, you will need both the kubectl and helm command line tools configured to reach your target cluster.

</details>

<details>
    <summary>(Optional) Two other servers</summary>

For one of the lateral movement demos, you will need two more cloud servers and the SSH credentials to reach them. These servers don't need to be large; a t2.micro instance on AWS is sufficient. Similar to the cluster, these should not be used for other services, as the installation and demos destructively modify some machine configuration.

</details>

### Installation

First, make sure you have `kubectl` and `helm` installed, and a configuration pointing to the cluster you want to install on. Then, clone this repository.

To install the required resources, run the install script:

```sh
./scripts/install.sh
```

Now would also be a good time to [install Spyderbat on the cluster](https://docs.spyderbat.com/installation/spyderbat-nano-agent/kubernetes), if you haven't already. If you would like to test out the Falco integration, take a look at the Falco Event Generator test in the next step.

### Accessing

To access the guidebook and walk through the samples, run the access command:

```sh
./scripts/access.sh
```

This will use kubectl to set up port-forwarding rules to allow you to connect directly to all of the resources you just installed.

Visit [localhost:8800](http://localhost:8800) to open the guidebook and get started.

### Clean-up

Due to the nature of these demos, it is impossible for an automated script to remove all traces of the eval environment. However, if you accidentally installed in the wrong cluster, or want to do a fresh re-install, use the uninstall script:

```sh
./scripts/uninstall.sh
```

This script will remove all of the installed kubernetes namespaces and will attempt to restore the two external servers to their original states.

To fully reset the environment after being used for demos, it is best to re-create the cluster and external servers.

## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md).

