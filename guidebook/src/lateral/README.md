# Lateral Movement

## Running the Exploit

For this scenario, we are going to use some left-over debugging resources used by Bob, a developer who decided he needed to be able to get direct access to the RSVP app to debug it. Since he forgot to clan up after solving the bugs, there is now an extra pod in the App Policy namespace with some convenient developer tools. Let's get into it.

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

And it looks like the SSH key is still here:

```
bash-4.2# ls ~
bob_key
```

Let's follow in Bob's footsteps.

```sh
ssh admin@payroll-calculator -i ~/bob_key -p 2222
```

Now, we have ended up on one of the RSVP app's pods. Here, we have access to install extra tools if necessary:

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

This test should actually trigger two Spydertraces - one for each machine we have accessed. On the Spyderbat Console's Dashboard page, navigate to the Security tab. Under "Recent Spydertraces with a score > 50", there are two new traces: `container_shell` (or ) and `root_shell`. Select these two traces and click "Start Process Investigation" to start investigating these two traces together.

In the investigation view, we can now clearly see what happened. On one side, we accessed the bobdev container, took a look around, and then ran an SSH command to connect to the other, an SSH server. After connecting, `apk` was run, followed by `su` and `crontab`.

![An example graph of this exploit.](./edited_lateral_movement_graph.png)

The graph you see may differ a bit from what is shown here. To clean up the trace, you can right-click on un-needed branches of the causal tree and remove them, or shift them left or right to make the sequence easier to read.

## Next Steps

With the data gathered in this investigation, we can now prepare a few recovery steps:

- Remove the crontab entry that was added for persistence.
- Remove the SSH server and development container that Bob left.
- Check for any other containers that should not exist in the production environment.
- Have Bob rotate his SSH keys.
- Revise debugging procedures for the affected applications.

