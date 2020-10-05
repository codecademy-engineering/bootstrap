# Ansible scripts for Fedora Linux

## Pre-requisites

To install Ansible run:

```
dnf install ansible
```

## Run Ansible playbooks

First, we will install some yum/dnf repositories using sudo with the command:

```
cd ansible
sudo ansible-playbook yum_repos.yml
```

Finally we will run the rest of the playbook after being prompted for the user's password (assuming the user is in the
wheel group and capable of running sudo):

```
ansible-playbook linux_bootstrap.yml --ask-become-pass
```

This prompt for the root password is because we are going to install some packages at the system level. Other tools
(that can be installed in an alternate directory) such as `aws-vault` or `terraform` will be installed for your user (in
the ~/bin directory) as opposed to system wide as root.

## Versions of installed tools

Some of these tools versions are set in the `linux_bootstrap.yml` file as Ansible variables (`vars`). These can be
modified as the `bootstrap.sh` shell script VARS are modified to be kept in line with versions pinned there.

## Caveats

The below caveats are listed to inform the reader about workarounds that were necessary to install these tools.

* These ansible playbooks assume the user is running on Fedora 32.
* These ansible playbooks assume the user is running the bash shell.
* We do not install Docker currently due to the fact that Docker is not supported/functional without some
workarounds on Fedora 32. Follow [this](https://fedoramagazine.org/docker-and-fedora-32/) document to install Docker on Fedora 32,
but do not run the `firewall-cmd` commands to whitelist Docker as I had trouble with my firewall zones after I tried following them.
* The version of helmfile is currently hardcoded to install v0.129.3 due to limitations of installing from Github releases.
* MongoDB is installed from the RedHat 8 repository, hardcoded to version 4.4 for now because this is the latest RedHat version and MongoDB version.
* We install both Helm v2.14.3 and Helm v3.3.4 (both hardcoded at that version currently) separately for support of some of our older apps using Helm 2.
* The version of helm-diff is currently hardcoded to install v2.11.0+5.

## Terraform

We install tfenv to manage terraform versions for you, but do not configure any version initially. After this is
installed you will want to run the following to get your versions setup as you wish:

```
tfenv install          # This will install the most recent terraform version
tfenv use 0.13.4       # This will tell tfenv to use the most recent version
tfenv install 0.12.29  # This will install an earlier 'major' version of terraform
```

You can switch back and forth between the two now, using `tfenv use XXX`.
