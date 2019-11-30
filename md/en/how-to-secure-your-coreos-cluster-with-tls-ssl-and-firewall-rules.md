---
author: Brennen Bearnes
date: 2015-12-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-your-coreos-cluster-with-tls-ssl-and-firewall-rules
---

# How To Secure Your CoreOS Cluster with TLS/SSL and Firewall Rules

## Introduction

If you are planning to run a CoreOS cluster in a network environment outside of your control, such as within a shared datacenter or across the public internet, you may have noticed that `etcd` communicates by making unencrypted HTTP requests. It’s possible to mitigate the risks of that behavior by configuring an IPTables firewall on each node in the cluster, but a complete solution would ideally use an encrypted transport layer.

Fortunately, `etcd` supports peer-to-peer TLS/SSL connections, so that each member of a cluster is authenticated and all communication is encrypted. In this guide, we’ll begin by provisioning a simple cluster with three members, then configure HTTPS endpoints and a basic firewall on each machine.

## Prerequisites

This guide builds heavily on concepts discussed in [this introduction to CoreOS system components](an-introduction-to-coreos-system-components) and [this guide to setting up a CoreOS cluster on DigitalOcean](how-to-set-up-a-coreos-cluster-on-digitalocean).

You should be familiar with the basics of `etcd`, `fleetctl`, `cloud-config` files, and generating a discovery URL.

In order to create and access the machines in your cluster, you’ll need an SSH public key associated with your DigitalOcean account. For detailed information about using SSH keys with DigitalOcean, [see here](how-to-use-ssh-keys-with-digitalocean-droplets).

If you want to use the DigitalOcean API to create your CoreOS machines, refer to [this tutorial](how-to-use-the-digitalocean-api-v2#how-to-generate-a-personal-access-token) for information on how to generate and use a Personal Access Token with write permissions. Use of the API is optional, but may save you time in the long run, particularly if you anticipate building larger clusters.

## Generate a New Discovery URL

Retrieve a new discovery URL from discovery.etcd.io, either by visiting [https://discovery.etcd.io/new?size=3](https://discovery.etcd.io/new?size=3) in your browser and copying the URL displayed, or by using `curl` from the terminal on your local machine:

    curl -w "\n" "https://discovery.etcd.io/new?size=3"

Save the returned URL; we’ll use it in our `cloud-config` shortly.

## Write a Cloud-Config File Including HTTPS Configuration

We’ll start by writing a `cloud-config`. The `cloud-config` will be supplied as **user data** when initializing each server, defining important configuration details for the cluster. This file will be long, but shouldn’t wind up much more complicated than the version in the [basic cluster guide](how-to-set-up-a-coreos-cluster-on-digitalocean). We’ll tell `fleet` explicitly to use HTTPS endpoints, enable a service called `iptables-restore` for our firewall, and write out configuration files telling `etcd` and `fleet` where to find SSL certificates.

Open a terminal on your local machine, make sure you’re in your home directory, and use `nano` (or your favorite text editor) to create and open `~/cloud-config.yml`:

    cd ~
    nano cloud-config.yml

Paste the following, then change `https://discovery.etcd.io/token` in the `etcd2` section to the discovery URL you claimed in the last section.

You can also remove the `iptables-restore` section, if you don’t want to enable a firewall.

Be careful with indentation when pasting. The `cloud-config` is written in YAML, which is sensitive to whitespace. See comments within the file for info on specific lines, then we’ll go over some important sections in greater detail.

~/cloud-config.yml

    #cloud-config
    
    coreos:
      etcd2:
        # generate a new token for each unique cluster from https://discovery.etcd.io/new:
        discovery: https://discovery.etcd.io/token
        # multi-region deployments, multi-cloud deployments, and Droplets without
        # private networking need to use $public_ipv4:
        advertise-client-urls: https://$private_ipv4:2379,https://$private_ipv4:4001
        initial-advertise-peer-urls: https://$private_ipv4:2380
        # listen on the official ports 2379, 2380 and one legacy port 4001:
        listen-client-urls: https://0.0.0.0:2379,https://0.0.0.0:4001
        listen-peer-urls: https://$private_ipv4:2380
      fleet:
        # fleet defaults to plain HTTP - explicitly tell it to use HTTPS on port 4001:
        etcd_servers: https://$private_ipv4:4001
        public-ip: $private_ipv4 # used for fleetctl ssh command
      units:
        - name: etcd2.service
          command: start
        - name: fleet.service
          command: start
        # enable and start iptables-restore
        - name: iptables-restore.service
          enable: true
          command: start
    write_files:
      # tell etcd2 and fleet where our certificates are going to live:
      - path: /run/systemd/system/etcd2.service.d/30-certificates.conf
        permissions: 0644
        content: |
          [Service]
          # client environment variables
          Environment=ETCD_CA_FILE=/home/core/ca.pem
          Environment=ETCD_CERT_FILE=/home/core/coreos.pem
          Environment=ETCD_KEY_FILE=/home/core/coreos-key.pem
          # peer environment variables
          Environment=ETCD_PEER_CA_FILE=/home/core/ca.pem
          Environment=ETCD_PEER_CERT_FILE=/home/core/coreos.pem
          Environment=ETCD_PEER_KEY_FILE=/home/core/coreos-key.pem
      - path: /run/systemd/system/fleet.service.d/30-certificates.conf
        permissions: 0644
        content: |
          [Service]
          # client auth certs
          Environment=FLEET_ETCD_CAFILE=/home/core/ca.pem
          Environment=FLEET_ETCD_CERTFILE=/home/core/coreos.pem
          Environment=FLEET_ETCD_KEYFILE=/home/core/coreos-key.pem
    

As an optional step, you can paste your `cloud-config` into [the official CoreOS Cloud Config Validator](https://coreos.com/validate/) and press **Validate Cloud-Config**.

Save the file and exit. In `nano`, you can accomplish this with **Ctrl-X** to exit, **y** to confirm writing the file, and **Enter** to confirm the filename to save.

Let’s look at a handful of specific blocks from `cloud-init.yml`. First, the `fleet` values:

      fleet:
        # fleet defaults to plain HTTP - explicitly tell it to use HTTPS:
        etcd_servers: https://$private_ipv4:4001
        public-ip: $private_ipv4 # used for fleetctl ssh command

Notice that `etcd_servers` is set to an `https` URL. For plain HTTP operation, this value doesn’t need to be set. Without explicit configuration, however, HTTPS will fail. (`$private_ipv4` is a variable understood by the CoreOS initialization process, not one you need to change.)

Next we come to the `write_files` block. Values are broken into a filesystem `path`, `permissions` mask, and `content`, which contains the desired contents of a file. Here, we specify that `systemd` unit files for the `etcd2` and `fleet` services should set up environment variables pointing to the TLS/SSL certificates we’ll be generating:

    write_files:
      # tell etcd2 and fleet where our certificates are going to live:
      - path: /run/systemd/system/etcd2.service.d/30-certificates.conf
        permissions: 0644
        content: |
          [Service]
          # client environment variables
          Environment=ETCD_CA_FILE=/home/core/ca.pem
          ...
      - path: /run/systemd/system/fleet.service.d/30-certificates.conf
        permissions: 0644
        content: |
          [Service]
          # client auth certs
          Environment=FLEET_ETCD_CAFILE=/home/core/ca.pem
          ...

While we tell the services where to find certificate files, we can’t yet provide the files themselves. In order to that, we’ll need to know the private IP address of each CoreOS machine, which is only available once the machines have been created.

**Note:** On CoreOS Droplets, the contents of `cloud-config` cannot be changed after the Droplet is created, and the file is re-executed on every boot. You should avoid using the `write-files` section for any configuration you plan to modify after your cluster is built, since it will be reset the next time the Droplet starts up.

## Provision Droplets

Now that we have a `cloud-config.yml` defined, we’ll use it to provision each member of the cluster. On DigitalOcean, there are two basic approaches we can take: Via the web-based Control Panel, or making calls to the DigitalOcean API using cURL from the command line.

### Using the DigitalOcean Control Panel

Create three new CoreOS Droplets within the same datacenter region. Make sure to check **Private Networking** and **Enable User Data** each time.

- **coreos-1**
- **coreos-2**
- **coreos-3**

In the **User Data** field, paste the contents of `cloud-config.yml` from above, making sure you’ve inserted your discovery URL in the `discovery` field near the top of the file.

### Using the DigitalOcean API

As an alternative approach which may save repetitive pasting into fields, we can write a short Bash script which uses `curl` to request a new Droplet from the DigitalOcean API with our `cloud-config`, and invoke it once for each Droplet. Open a new file called `makecoreos.sh` with `nano` (or your text editor of choice):

    cd ~
    nano makecoreos.sh

Paste and save the following script, adjusting the `region` and `size` fields as-desired for your cluster (the defaults of `nyc3` and `512mb` are fine for demonstration purposes, but you may want a different region or bigger Droplets for real-world projects):

~/makecoreos.sh

    #!/usr/bin/env bash
    
    # A basic Droplet create request.
    curl -X POST "https://api.digitalocean.com/v2/droplets" \
         -d'{"name":"'"$1"'","region":"nyc3","size":"512mb","private_networking":true,"image":"coreos-stable","user_data":
    "'"$(cat ~/cloud-config.yml)"'",
             "ssh_keys":["'$DO_SSH_KEY_FINGERPRINT'"]}' \
         -H "Authorization: Bearer $TOKEN" \
         -H "Content-Type: application/json"

Now, let’s set the environment variables `$DO_SSH_KEY_FINGERPRINT` and `$TOKEN` to the fingerprint of an SSH key associated with your DigitalOcean account and your API Personal Access Token, respectively.

For information about getting a Personal Access Token and using the API, refer to [this tutorial](how-to-use-the-digitalocean-api-v2).

In order to find the fingerprint of a key associated with your account, check [the **Security** section of your account settings](https://cloud.digitalocean.com/settings/security), under **SSH Keys**. It will be in the form of a [public key fingerprint](https://en.wikipedia.org/wiki/Public_key_fingerprint), something like `43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8`.

We use `export` here so that child processes of the shell, like `makecoreos.sh`, will be able to access the variables. Both must be set in the current shell any time the script is used, or the API call will fail:

    export DO_SSH_KEY_FINGERPRINT="ssh_key_fingerprint"
    export TOKEN="your_personal_access_token"

**Note:** If you’ve just generated a Personal Access Token for the API, remember to keep it handy and secure. There’s no way to retrieve it after it’s shown to you on first creation, and anyone with the token can control your DigitalOcean account.

Once we’ve set environment variables for each of the required credentials, we can run the script to create each desired Droplet. `makecoreos.sh` uses its first parameter to fill out the `name` field in its call to the API:

    bash makecoreos.sh coreos-1
    bash makecoreos.sh coreos-2
    bash makecoreos.sh coreos-3

You should see JSON output describing each new Droplet, and all three should appear in your list of Droplets in the Control Panel. It may take a few seconds for them to finish booting.

## Log in to coreos-1

Whether you used the Control Panel or the API, you should now have three running Droplets. Now is a good time to make note of their public and private IPs, which are available by clicking on an individual Droplet in the Control Panel, then clicking on the **Settings** link. The private IP address of each Droplet will be needed when generating certificates and configuring a firewall.

Let’s test a Droplet. Make sure that your SSH key is added to your local SSH agent:

    eval $(ssh-agent)
    ssh-add

Find the public IP address of **coreos-1** in the DigitalOcean Control Panel, and connect with SSH agent forwarding turned on:

    ssh -A core@coreos-1_public_ip

On first login to any member of the cluster, we are likely to receive an error message from `systemd`:

    OutputCoreOS stable (766.5.0)
    Failed Units: 1
      iptables-restore.service

This indicates that the firewall hasn’t yet been configured. For now, it’s safe to ignore this message. (If you elected not to enable the firewall in your `cloud-config`, you won’t see an error message. You can always enable the `iptables-restore` service later.)

Before we worry about the firewall, let’s get the `etcd2` instances on each member of the cluster talking to one another.

## Use CFSSL to Generate Self-Signed Certificates

[CFSSL](https://github.com/cloudflare/cfssl) is a toolkit for working with TLS/SSL certificates, published by CloudFlare. At the time of this writing, it’s the CoreOS maintainers’ chosen tool for generating self-signed certificates, in preference to OpenSSL and the now-deprecated `etcd-ca`.

### Install CFSSL on Your Local Machine

CFSSL requires a working Go installation to install from source. See [this guide to installing Go](how-to-install-go-1-5-1-on-ubuntu-14-04).

Make sure your `$GOPATH` is set correctly and added to your `$PATH`, then use `go get` to install the `cfssl` commands:

    export GOPATH=~/gocode
    export PATH=$PATH:$GOPATH/bin
    go get -u github.com/cloudflare/cfssl/cmd/cfssl
    go get -u github.com/cloudflare/cfssl/...

As an alternative approach, pre-built binaries can be retrieved from [pkg.cfssl.org](https://pkg.cfssl.org/). First make sure that `~/bin` exists and is in your path:

    mkdir -p ~/bin
    export PATH=$PATH:~/bin

Then use `curl` to retrieve the latest versions of `cfssl` and `cfssljson` for your platform:

    curl -s -L -o ~/bin/cfssl https://pkg.cfssl.org/R1.1/cfssl_linux-amd64
    curl -s -L -o ~/bin/cfssljson https://pkg.cfssl.org/R1.1/cfssljson_linux-amd64

Make sure the `cfssl` binaries are executable:

    chmod +x ~/bin/cfssl
    chmod +x ~/bin/cfssljson

### Generate a Certificate Authority

Now that the `cfssl` commands are installed, we can use them to generate a custom Certificate Authority which we’ll use to sign certificates for each of our CoreOS machines. Let’s start by making and entering a fresh directory to stash these files in:

    mkdir ~/coreos_certs
    cd ~/coreos_certs

Now, create and open `ca-config.json` in `nano` (or your favorite text editor):

    nano ca-config.json

Paste and save the following, which configures how `cfssl` will do signing:

~/coreos\_certs/ca-config.json

    {
        "signing": {
            "default": {
                "expiry": "43800h"
            },
            "profiles": {
                "client-server": {
                    "expiry": "43800h",
                    "usages": [
                        "signing",
                        "key encipherment",
                        "server auth",
                        "client auth"
                    ]
                }
            }
        }
    }

Of note here are the `expiry`, currently set to 43800 hours (or 5 years), and the `client-server` profile, which includes both `server auth` and `client auth` usages. We need both of these for peer-to-peer TLS.

Next, create and open `ca-csr.json`.

    nano ca-csr.json

Paste the following, adjusting `CN` and the `names` array as desired for your location and organization. It’s safe to use fictional values for the `hosts` entry as well as place and organization names:

~/coreos\_certs/ca-csr.json

    {
        "CN": "My Fake CA",
        "hosts": [
            "example.net",
            "www.example.net"
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "US",
                "L": "CO",
                "O": "My Company",
                "ST": "Lyons",
                "OU": "Some Org Unit"
            }
        ]
    }

If you want to compare these with default values for `ca-config.json` and `ca-csr.json`, you can print defaults with `cfssl`. For `ca-config.json`, use:

    cfssl print-defaults config

For `ca-csr.json`, use:

    cfssl print-defaults csr

With `ca-csr.json` and `ca-config.json` in place, generate the Certificate Authority:

    cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

### Generate and Sign Certificates for CoreOS Machines

Now that we have a Certificate Authority, we can write defaults for a CoreOS machine:

Create and open `coreos-1.json`:

    nano coreos-1.json

Paste and save the following, adjusting it for the private IP address of **coreos-1** (visible in the DigitalOcean Control Panel by clicking on an individual Droplet):

~/coreos\_certs/coreos-1.json

    {
        "CN": "coreos-1",
        "hosts": [
            "coreos-1",
            "coreos-1.local",
            "127.0.0.1",
            "coreos-1_private_ip"
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "US",
                "L": "Lyons",
                "ST": "Colorado"
            }
        ]
    }

The most important parts are `CN`, which should be your hostname, and the `hosts` array, which must contain all of:

- your local hostname(s)
- `127.0.0.1`
- the CoreOS machine’s private IP address (not its public-facing IP)

These will be added to the resulting certificate as **[subjectAltNames](https://en.wikipedia.org/wiki/SubjectAltName)**. `etcd` connections (including to the local loopback device at `127.0.0.1`) require the certificate to have a SAN matching the connecting hostname.

You can also change the `names` array to reflect your location, if desired. Again, it’s safe to use fictional values for placenames.

Repeat this process for each remaining machine, creating a matching `coreos-2.json` and `coreos-3.json` with the appropriate `hosts` entries.

**Note:** If you’d like to take a look at default values for `coreos-1.json`, you can use `cfssl`:

    cfssl print-defaults csr

Now, for each CoreOS machine, generate a signed certificate and upload it to the correct machine:

    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client-server coreos-1.json | cfssljson -bare coreos
    chmod 0644 coreos-key.pem
    scp ca.pem coreos-key.pem coreos.pem core@coreos-1_public_ip:

This will create three files (`ca.pem`, `coreos-key.pem`, and `coreos.pem`), make sure permissions are correct on the keyfile, and copy them via `scp` to **core** ’s home directory on **coreos-1**.

Repeat this process for each of the remaining machines, keeping in mind that each invocation of the command will overwrite the previous set of certificate files:

    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client-server coreos-2.json | cfssljson -bare coreos
    chmod 0644 coreos-key.pem
    scp ca.pem coreos-key.pem coreos.pem core@coreos-2_public_ip:

    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client-server coreos-3.json | cfssljson -bare coreos
    chmod 0644 coreos-key.pem
    scp ca.pem coreos-key.pem coreos.pem core@coreos-3_public_ip:

## Check etcd2 Functionality on coreos-1

With certificates in place, we should be able to run `fleetctl` on **coreos-1**. First, log in via SSH:

    ssh -A core@coreos-1_public_ip

Next, try listing all the machines in the cluster:

    fleetctl list-machines

You should see an identifier for each machine listed along with its private IP address:

    OutputMACHINE IP METADATA
    7cb57440... 10.132.130.187 -
    d91381d4... 10.132.87.87 -
    eeb8726f... 10.132.32.222 -

If `fleetctl` hangs indefinitely, it may be necessary to restart the cluster. Exit to your local machine:

    exit

Use SSH to send `reboot` commands to each CoreOS machine:

    ssh core@coreos-1_public_ip 'sudo reboot'
    ssh core@coreos-2_public_ip 'sudo reboot'
    ssh core@coreos-3_public_ip 'sudo reboot'

Wait a few moments, re-connect to **coreos-1** , and try `fleetctl` again.

## Configure an IPTables Firewall on Cluster Members

With certificates in place, it should be impossible for other machines on the local network to control your cluster or extract values from `etcd2`. Nevertheless, it’s a good idea to reduce the available attack surface if possible. In order to limit our network exposure, we can add some simple firewall rules to each machine, blocking most local network traffic from sources other than peers in the cluster.

Remember that, if we enabled the `iptables-restore` service in `cloud-config`, we’ll see a `systemd` error message when first logging in to a CoreOS machine:

    OutputCoreOS stable (766.5.0)
    Failed Units: 1
      iptables-restore.service

This lets us know that, although the service is enabled, `iptables-restore` failed to load correctly. We can diagnose this by using `systemctl`:

    systemctl status -l iptables-restore

    Output● iptables-restore.service - Restore iptables firewall rules
       Loaded: loaded (/usr/lib64/systemd/system/iptables-restore.service; enabled; vendor preset: disabled)
       Active: failed (Result: exit-code) since Wed 2015-11-25 00:01:24 UTC; 27min ago
      Process: 689 ExecStart=/sbin/iptables-restore /var/lib/iptables/rules-save (code=exited, status=1/FAILURE)
     Main PID: 689 (code=exited, status=1/FAILURE)
    
    Nov 25 00:01:24 coreos-2 systemd[1]: Starting Restore iptables firewall rules...
    Nov 25 00:01:24 coreos-2 systemd[1]: iptables-restore.service: Main process exited, code=exited, status=1/FAILURE
    Nov 25 00:01:24 coreos-2 systemd[1]: Failed to start Restore iptables firewall rules.
    Nov 25 00:01:24 coreos-2 iptables-restore[689]: Can't open /var/lib/iptables/rules-save: No such file or directory
    Nov 25 00:01:24 coreos-2 systemd[1]: iptables-restore.service: Unit entered failed state.
    Nov 25 00:01:24 coreos-2 systemd[1]: iptables-restore.service: Failed with result 'exit-code'.

There’s a lot of information here, but the most useful line is the one containing `iptables-restore[689]`, which is the name of the process `systemd` attempted to run along with its process id. This is where we’ll often find the actual error output of failed services.

The firewall failed to restore because, while we enabled `iptables-restore` in `cloud-config`, we haven’t yet provided it with a file containing our desired rules. We could have done this before we created the Droplets, except that there’s no way to know what IP addresses will be allocated to a Droplet before its creation. Now that we know each private IP, we can write a ruleset.

Open a new file in your editor, paste the following, and replace `coreos-1_private_ip`, `coreos-2_private_ip`, and `coreos-3_private_ip` with the private IP address of each CoreOS machine. You may also need to adjust the section beneath `Accept all TCP/IP traffic...` to reflect public services you intend to offer from the cluster, although this version should work well for demonstration purposes.

/var/lib/iptables/rules-save

    *filter
    :INPUT DROP [0:0]
    :FORWARD DROP [0:0]
    :OUTPUT ACCEPT [0:0]
    
    # Accept all loopback (local) traffic:
    -A INPUT -i lo -j ACCEPT
    
    # Accept all traffic on the local network from other members of
    # our CoreOS cluster:
    -A INPUT -i eth1 -p tcp -s coreos-1_private_ip -j ACCEPT
    -A INPUT -i eth1 -p tcp -s coreos-2_private_ip -j ACCEPT
    -A INPUT -i eth1 -p tcp -s coreos-3_private_ip -j ACCEPT
    
    # Keep existing connections (like our SSH session) alive:
    -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    
    # Accept all TCP/IP traffic to SSH, HTTP, and HTTPS ports - this should
    # be customized for your application:
    -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
    
    # Accept pings:
    -A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
    -A INPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT
    -A INPUT -p icmp -m icmp --icmp-type 11 -j ACCEPT
    COMMIT
    

Copy the above to your clipboard, log in to **coreos-1** , and open `rules-save` using [Vim](installing-and-using-the-vim-text-editor-on-a-cloud-server), the default text editor on CoreOS:

    ssh -A core@coreos-1_public_ip

    sudo vim /var/lib/iptables/rules-save

Once inside the editor, type `:set paste` and press **Enter** to make sure that auto-indentation is turned off, then press **i** to enter insert mode and paste your firewall rules. Press **Esc** to leave insert mode and **:wq** to write the file and quit.

**Warning:** Make sure there’s a trailing newline on the last line of the file, or IPTables may fail with confusing syntax errors, despite all commands in the file appearing correct.

Finally, make sure that the file has appropriate permissions (read and write for user, read-only for group and world):

    sudo chmod 0644 /var/lib/iptables/rules-save

Now we should be ready to try the service again:

    sudo systemctl start iptables-restore

If successful, `systemctl` will exit silently. We can check the status of the firewall in two ways. First, by using `systemctl status`:

    sudo systemctl status -l iptables-restore

And secondly by listing the current `iptables` rules themselves:

    sudo iptables -v -L

We use the `-v` option to get verbose output, which will let us know what interface a given rule applies to.

Once you’re confident that the firewall on **coreos-1** is configured, log out:

    exit

Next, repeat this process to install `/var/lib/iptables/rules-save` on **coreos-2** and **coreos-3**.

## Conclusion

In this guide, we’ve defined a basic CoreOS cluster with three members, providing each with a TLS/SSL certificate for authentication and transport security, and used a firewall to block connections from other Droplets on the local data center network. This helps mitigate many of the basic security concerns involved in using CoreOS on a shared network.

From here, you can apply the techniques in the rest of [this series on getting started with CoreOS](https://www.digitalocean.com/community/tutorial_series/getting-started-with-coreos-2) to define and manage services.
