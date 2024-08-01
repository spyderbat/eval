# Scenario - Supply Chain attack and application policies

This scenario demonstrates a supply chain attack where a container image is getting an update with malicious code to create a backdoor to a kubernetes cluster environment. It shows how through the use of policies for applications running on the cluster, unanticipated changes in the behavior of these application can be detected early and remediated.

## Pre-requisites
You will need
- a cluster where you can deploy services, deployments, pods, with access to docker image hub for pulling images
- a kubectl client
- a kubectl configuration with its current context pointing to the cluster

## Initial setup

If you have not yet done the inital installation steps for these attack scenarios, refer to [Spyderbat eval repository](https://github.com/spyderbat/eval)

If your setup was successful, you should see a namespace called `app-policy` in your cluster, and some resources in it, like so:
```
kubectl get all -n app-policy
NAME                            READY   STATUS    RESTARTS   AGE
pod/mongodb-66b5d7df55-b6q5j    1/1     Running   0          18h
pod/rsvp-app-587559dbf4-fnvzq   1/1     Running   0          18h
pod/rsvp-app-587559dbf4-mbxkl   1/1     Running   0          18h

NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/mongodb    ClusterIP   10.43.220.107   <none>        27017/TCP      25h
service/rsvp-app   NodePort    10.43.201.79    <none>        80:30135/TCP   25h

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mongodb    1/1     1            1           25h
deployment.apps/rsvp-app   2/2     2            2           25h

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/mongodb-66b5d7df55    1         1         1       18h
replicaset.apps/rsvp-app-587559dbf4   2         2         2       18h
```


## Running the Exploit

> This exploit is based on <a href="https://madhuakula.com/kubernetes-goat/docs/scenarios/scenario-4/container-escape-to-the-host-system-in-kubernetes-containers/welcome" target="_blank">a Kubernetes Goat scenario</a>, updated to be compatible with modern Kubernetes.
One of the assets we have added to the cluster is a system monitor that has more permissions than is really necessary. To start, visit [localhost:1233](http://127.0.0.1:1233/), which gives a shell interface for the system monitor pod. Ideally, this shell is restricted to the container. However, running `mount` reveals that there is a link to the host system:

```sh
mount
```

Within all of the mount entries, there is a `/host-system` folder that seems to link to the host machine. Additionally, running `capsh` shows that everything is unlocked - meaning we can run chroot:

```sh
capsh --print
```

```sh
chroot /host-system bash
```

Now, we are in the root of the host system, which gives us all kinds of access. From here we could install an ssh backdoor key in the known_hosts file, query the AWS IMDS service to impersonate the AWS node (if the cluster is hosted on AWS). If the node is configured correctly, we might even be able to get the kubelet's configuration file, located in the `/var/lib/kubelet` directory. Using the credentials inside, we might be able to get access to more of the cluster. For demonstration purposes, let's install a backdoor key into the node:

```sh
# if this were a real backdoor, we could put a real ssh public key here
echo 'ssh-rsa BACKDOOR_KEY eve@example.com' >> /root/.ssh/authorized_keys
```

## Investigating the Results

Performing this exploit will trigger a number of red flags which are detected and collected into a single Spydertrace object. In the Spyderbat Console, navigate to the Dashboard page. In the Security tab, under "Recent Spydertraces with Score > 50", a new trace should appear, likely named "command_gotty", "root_shell", or "container_escape_using_chroot...". Selecting this Spydertrace, we can select "Start Process Investigation" to see the events of the exploit layed out in a Causal Tree in the investigation view:

![A section of the Spydertrace featuring one of my chroot commands](./chroot_flag_graph.png)

## Next Steps

Now that the vulnerable container has been identified and the scope of the resulting access determined, steps can be taken to end the existing access and update the pod configuration to remove the possibility of a chroot.