# Spyderbat Evaluation Environment

A set of tools for evaluating and showcasing the features offered by Spyderbat.

## Getting Started

### Installation

First, make sure you have `kubectl` installed, and a configuration pointing to the cluster you want to install on. Then, clone this repository.

To install the required resources, run the `install.sh` script provided at the root of the repository. Now would also be a good time to [install Spyderbat on the cluster](https://docs.spyderbat.com/installation/spyderbat-nano-agent/kubernetes), if you haven't already.

### Accessing

To access the guidebook and walk through the samples, run the `access.sh` command. This will use kubectl to set up port-forwarding rules to allow you to connect directly to all of the resources you just installed.

Visit [localhost:8000](http://localhost:8000) to open the guidebook and get started.

## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md).

