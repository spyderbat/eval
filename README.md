# Spyderbat Evaluation Environment

A set of tools for evaluating and showcasing the features offered by Spyderbat.

## Getting Started

### Installation

First, make sure you have `kubectl` and `helm` installed, and a configuration pointing to the cluster you want to install on. Then, clone this repository.

To install the required resources, run the `install.sh` script provided in the `scripts` directory. Now would also be a good time to [install Spyderbat on the cluster](https://docs.spyderbat.com/installation/spyderbat-nano-agent/kubernetes), if you haven't already.

The install script will automatically ask if you want to install Falco aside Spyderbat. If you would like to install it without the script, use this command:

```sh
helm repo add falcosecurity https://falcosecurity.github.io/charts 
helm repo update
helm install falco falcosecurity/falco \
    --create-namespace \
    --namespace falco \
    --set falcosidekick.enabled=true \
    --set falcosidekick.config.spyderbat.orguid="SPYDERBAT_ORG" \
    --set falcosidekick.config.spyderbat.apiurl="https://api.spyderbat.com" \
    --set falcosidekick.config.spyderbat.apikey="SPYDERBAT_API_KEY" \
    --set extra.args=\{"-p","%proc.pid"\} \
    --set driver.kind=modern_ebpf
```

### Accessing

To access the guidebook and walk through the samples, run the `access.sh` command in the scripts directory. This will use kubectl to set up port-forwarding rules to allow you to connect directly to all of the resources you just installed.

Visit [localhost:8000](http://localhost:8000) to open the guidebook and get started.

## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md).

