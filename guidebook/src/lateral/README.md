# Lateral Movement

## Running the Exploit

For this scenario, we are going to use some debugging resources left over by Bob, a developer who decided he needed to be able to get direct access to the RSVP app to debug it. Since he forgot to clean up after solving the bugs, there is now an extra pod in the App Policy namespace with some convenient developer tools.

Let's exec into the developer pod to begin.

```sh
kubectl exec -it -n lateral-movement bobdev -- /bin/bash
```

Taking a look at the bash history, it looks like Bob used SSH to get into another pod:

```
bash-4.2# history
    1  ls
    2  which ssh
    3  nslookup payroll-calculator
    4  curl payroll-calculator
    5  ssh admin@payroll-calculator -i ~/bob_key -p 2222
    6  history
```

He used a local key to log in, and it looks like the SSH key is still here:

```
bash-4.2# ls ~
bob_key
```

Let's follow in Bob's footsteps.

```sh
ssh admin@payroll-calculator -i ~/bob_key -p 2222
```

Now, we have ended up on one of the RSVP app's pods. Checking our permissions shows that we have quite a few permissions on this pod:

```
payroll-calculator-86c898b7d8-969q7:~$ whoami
admin
payroll-calculator-86c898b7d8-969q7:~$ sudo -l
User admin may run the following commands on payroll-calculator-86c898b7d8-969q7:
    (ALL) NOPASSWD: ALL
```

This means we have access to install extra tools if necessary:

```sh
sudo apk add nmap
```

Change to the root user:

```sh
sudo su -
```

Or add a Cron entry to ensure we can get back into this container later:

```sh
crontab -e
```

## Investigation

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

