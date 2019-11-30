---
author: Tyler Langlois
date: 2018-02-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-securely-manage-secrets-with-hashicorp-vault-on-ubuntu-16-04
---

# How To Securely Manage Secrets with HashiCorp Vault on Ubuntu 16.04

## Introduction

[Vault](https://www.vaultproject.io/) is an open-source tool that provides a secure, reliable way to store and distribute secrets like API keys, access tokens, and passwords. Software like Vault can be critically important when deploying applications that require the use of secrets or sensitive data.

In this tutorial, you will:

- Install Vault and configure it as a system service
- Initialize an encrypted on-disk data store
- Store and retrieve a sensitive value securely over TLS

With some additional policies in place, you’ll be able to use Vault to securely manage sensitive data for your various applications and tools.

As with any service that manages sensitive information, you should consider reading additional documentation regarding Vault’s deployment best practices before using it in a production-like environment. For example, [Vault’s production hardening guide](https://www.vaultproject.io/guides/production.html) covers topics such as policies, root tokens, and auditing.

## Prerequisites

Before you begin this guide you’ll need the following:

- One Ubuntu 16.04 server set up by following [the initial setup guide for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- An SSL certificate, which we will use to secure Vault’s HTTP API. You can get one for free by following [this Certbot standalone mode tutorial](how-to-use-certbot-standalone-mode-to-retrieve-let-s-encrypt-ssl-certificates).

## Step 1 — Installing Vault

HashiCorp provides Vault as a single binary, so we’ll download and install Vault’s executable manually.

First, download the compressed Vault zip archive for 64-bit Linux. You can find the link to the latest version (0.9.5 at the time of writing) on [Vault’s downloads page](https://www.vaultproject.io/downloads.html).

    wget https://releases.hashicorp.com/vault/0.9.5/vault_0.9.5_linux_amd64.zip

Then download the checksum for this file so you can verify the download.

    wget https://releases.hashicorp.com/vault/0.9.5/vault_0.9.5_SHA256SUMS

Next, verify the integrity of the zip archive. This is to confirm that the zip archive’s contents match what Hashicorp has released in version 0.9.5 of Vault.

    grep linux_amd64 vault_*_SHA256SUMS | sha256sum -c -

Each line in the `SHA256SUMS` file has a checksum and a filename, one for each zip archive that HashiCorp provides. The `grep` portion of the above command prints the line with the checksum and filename of the 64-bit Linux binary, then pipes (`|`) that line to the next command. The SHA-256 command checks, `-c`, that the file with the filename from that line matches the checksum from that line.

Running the command should indicate the archive is `OK`. If not, try re-downloading the file.

    Outputvault_0.9.5_linux_amd64.zip: OK

With the checksum verification complete, install the `unzip` command so you can decompress the archive. Make sure your package repository is up to date first.

    sudo apt-get update
    sudo apt-get install unzip

Then unzip the Vault binary into the working directory.

    unzip vault_*.zip

    OutputArchive: vault_0.9.5_linux_amd64.zip
      inflating: vault 

Move the Vault executable into a directory in the system’s `PATH` to make it accessible from your shell.

    sudo cp vault /usr/local/bin/

Finally, set a Linux capability flag on the binary. This adds extra security by letting the binary perform memory locking without unnecessarily elevating its privileges.

    sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

You can now use the `vault` command. Try checking Vault’s version to make sure it works.

    vault --version

    OutputVault v0.7.2 ('d28dd5a018294562dbc9a18c95554d52b5d12390')

The Vault executable is installed on your server, so the next step is to configure it to run as a system service.

## Step 2 — Creating the Vault Unit File

Systemd is Ubuntu’s init system which, among other things, manages the system’s services. In order to set Vault up as a system service, we need to set up the following things:

- A system user for the Vault daemon to run as
- A data directory to store Vault’s information
- Vault’s configuration file
- The `systemd` [unit file](understanding-systemd-units-and-unit-files) itself.

**Note** : In this tutorial, we’re using the [filesystem backend](https://www.vaultproject.io/docs/configuration/storage/filesystem.html) to store encrypted secrets on the local filesystem at `/var/lib/vault`. This is suitable for local or single-server deployments that do not need to be replicated. Other Vault backends, such as the Consul backend, will store encrypted secrets at rest within a distributed key/value store.

First, create a **vault** system user.

    sudo useradd -r -d /var/lib/vault -s /bin/nologin vault

Here, we use `/var/lib/vault` as the user’s home directory. This will be used as the Vault data directory. We also set the shell to `/bin/nologin` to restrict the user as a non-interactive system account.

Set the ownership of `/var/lib/vault` to the **vault** user and the **vault** group exclusively.

    sudo install -o vault -g vault -m 750 -d /var/lib/vault

Now let’s set up Vault’s configuration file, `/etc/vault.hcl`. You’ll use this to control various options in Vault, such as where encrypted secrets are stored.

Create `vault.hcl` using `nano` or your favorite text editor.

    sudo nano /etc/vault.hcl

Paste the following into the file, and make sure to substitute in your own domain name:

/etc/vault.hcl

    backend "file" {
            path = "/var/lib/vault"
    }
    
    listener "tcp" {
            tls_disable = 0
            tls_cert_file = "/etc/letsencrypt/live/example.com/fullchain.pem"
            tls_key_file = "/etc/letsencrypt/live/example.com/privkey.pem"
    
    }

This configuration file instructs Vault to store encrypted secrets in `/var/lib/vault` on-disk, and indicates that Vault should listen for connections via HTTPS using certificates generated from the Let’s Encrypt tutorial.

Save and close the file, then secure the Vault configuration file’s permissions by only allowing the **vault** user to read it.

    sudo chown vault:vault /etc/vault.hcl 
    sudo chmod 640 /etc/vault.hcl 

Next, to let Systemd manage the persistent Vault daemon, create a [unit file](understanding-systemd-units-and-unit-files) at `/etc/systemd/system/vault.service`.

    sudo nano /etc/systemd/system/vault.service

Copy and paste the following into the file. This allows Vault to run in the background as a persistent system service daemon.

/etc/systemd/system/vault.service

    [Unit]
    Description=a tool for managing secrets
    Documentation=https://vaultproject.io/docs/
    After=network.target
    ConditionFileNotEmpty=/etc/vault.hcl
    
    [Service]
    User=vault
    Group=vault
    ExecStart=/usr/local/bin/vault server -config=/etc/vault.hcl
    ExecReload=/usr/local/bin/kill --signal HUP $MAINPID
    CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
    Capabilities=CAP_IPC_LOCK+ep
    SecureBits=keep-caps
    NoNewPrivileges=yes
    KillSignal=SIGINT
    
    [Install]
    WantedBy=multi-user.target

The complete list of service unit options is extensive, but the most important configuration options to note in the above definition include:

- `ConditionFileNotEmpty` ensures that the `/etc/vault.hcl` configuration file exists.
- `User` and `Group`, which control the user permissions that the Vault daemon will run with.
- `ExecStart`, which points to the executable that we installed previously and defines what to start to run the service.
- `ExecReload`, which is called when Vault reloads its configuration file, e.g., when running `systemctl reload vault`.
- `[Install]`, which lets us run this service persistently at startup so we don’t need to start it manually after reboots.

Finally, Vault needs permission to read the certificates you created with Certbot. By default, these certificates and private keys are only accessible by **root**. To make these available securely, we’ll create a special group called **pki** to access these files. We will create the group and then add the **vault** user to it.

Save and close the file, then create the **pki** group.

    sudo groupadd pki

Update the permissions on the two directories in the `/etc/letsencrypt` directory to allow the **pki** group to read the contents.

    sudo chgrp pki /etc/letsencrypt/{archive,live}
    sudo chmod g+rx /etc/letsencrypt/{archive,live}

Then add the **vault** user to the **pki** group. This will grant Vault access to the certificates so that it can serve requests securely over HTTPS.

    sudo gpasswd -a vault pki

As a final step for convenience, add a rule in `/etc/hosts` to direct requests to Vault to `localhost`.

By default, Vault will only listen for requests from the loopback interface (`lo`, or address `127.0.0.1`). This is to ensure that the service is not exposed to the public internet before it has been properly secured. You can update this later, but for now, this configuration change will let us use the `vault` command and correctly resolve the HTTPS-secured domain name.

Replace `example.com` in the following command with domain you acquired the Let’s Encrypt certificate for:

    echo 127.0.0.1 example.com | sudo tee -a /etc/hosts

This appends the line `127.0.0.1 example.com` to `/etc/hosts` so that any HTTP requests to `example.com` are routed to `localhost`.

With the Vault executable set up, the service file written, and the Vault configuration file complete, we’re now ready to start Vault and initialize the secret store.

## Step 3 — Initializing Vault

When you first start Vault, it will be uninitialized, which means that it isn’t ready to get and store data.

The first time you start Vault, the backend that actually stores the encrypted secrets is uninitialized, too. Start the Vault system service to initialize the backend and start running Vault itself.

    sudo systemctl start vault

You can run a quick check to confirm the service has started successfully.

    sudo systemctl status vault

The output of that command should include several pieces of information about the running service, such as its process ID and resource usage. Ensure that the following line is included in the output, which indicates the service is running correctly.

    Output. . .
    Active: active (running)
    . . .

If the service is not active, take a look at the accompanying log lines at the end of the command’s output to see Vault’s output, which can help pinpoint any issues.

Next, we’ll set an environment variable to tell the `vault` command how to connect to the Vault server. Here, Vault has been configured to listen on the local loopback interface only, so set the `VAULT_ADDR` environment variable to the local HTTPS endpoint.

    export VAULT_ADDR=https://example.com:8200

The `vault` command can now communicate with the daemon. Note that defining the actual hostname instead of simply `localhost` or `127.0.0.1` is necessary to properly validate the HTTPS certificate.

Confirm that the vault is in an uninitialized state by checking its status.

    vault status

The server should return a 400 error that says the server is not yet initialized.

    OutputError checking seal status: Error making API request.
    
    URL: GET https://example.com:8200/v1/sys/seal-status
    Code: 400. Errors:
    
    * server is not yet initialized

There are two pieces of information that Vault will expose at initialization time that will _not_ be available at any other point:

- **Initial root token**. This is equivalent to root permissions to your Vault deployment, which allows the management of all Vault policies, mounts, and so on.
- **Unseal keys**. These are used to unseal Vault when the daemon starts, which permits the Vault daemon to decrypt the backend secret store.

More specifically, Vault’s unsealing process decrypts the backend using a key formed by key shares. That is, when initializing Vault, you may choose how many unseal keys to create and how many are necessary at unseal time to successfully unseal Vault.

A typical, simple value for the unseal parameters would be to create three keys and require at least two of those keys at unseal time. This permits the important key shares to be separated and stored in distinct locations to ensure that compromising one is not sufficient to unseal Vault.

In other words, whenever Vault is started, _at least two_ unseal keys will be required in order to make the service become available and ready to use. While sealed, the files that store the actual secret values will remain encrypted and inaccessible.

Initialize Vault with the aforementioned parameters:

    vault init -key-shares=3 -key-threshold=2

Save each unseal token and the initial root token in a secure way. For example, one option would be to store one unseal key in a password manager, another on a USB drive, and another in GPG-encrypted file.

You can now unseal Vault using the newly created unseal tokens. Begin by unsealing using one key.

    vault operator unseal

The command will ask for an unseal token:

    OutputKey (will be hidden):

After entering it, the output from the command will indicate that the unsealing is in progress, but still requires one more unsealing key before Vault is ready for use.

    OutputSealed: true
    Key Shares: 3
    Key Threshold: 2
    Unseal Progress: 1
    Unseal Nonce: 3bdc838e-1b74-bc13-1d6f-c772f1694d83

Run the `unseal` command again.

    vault operator unseal

And enter a different token than the one you already used:

    OutputKey (will be hidden):

The command’s output indicates that the unseal process and completed successfully.

    OutputSeal Type shamir
    Sealed false
    Total Shares 3
    Threshold 2
    Version 0.9.5
    Cluster Name vault-cluster-5511b3ff
    Cluster ID 53522534-8ee1-8aec-86db-e13e4a499dd0
    HA Enabled false

Vault is now be unsealed and ready for use. These unseal steps are necessary whenever Vault is started or restarted.

However, unsealing is a distinct process from normal interaction with Vault (such as reading and writing values), which are authenticated by _tokens_. In the last step, we’ll create the necessary access tokens and policies to store secret values and read/write to specific paths in Vault.

## Step 4 — Reading and Writing Secrets

There are several [secret backends enumerated in the Vault documentation](https://www.vaultproject.io/docs/secrets/index.html), but for this example we will use the [generic secret backend](https://www.vaultproject.io/docs/secrets/generic/index.html). This backend stores simple key/value pairs in Vault.

First, save the previously generated root token to a shell variable for ease of use.

    root_token=your_root_token_here

To begin, write a value to a path within Vault.

    VAULT_TOKEN=$root_token vault write secret/message value=mypassword

In this command, the `secret/` prefix indicates that we are writing to the `generic` backend mounted at the `secret` path, and we are storing the key `value` at the path `message` with the value `mypassword`. We used the root token, which has superuser privileges, to write the generic secret.

In a real-world scenario, you may store values like API keys or passwords that external tools can consume. Although you may read the secret value again using the root token, it is illustrative to generate a less privileged token with read-only permissions to our single secret.

Create a file called `policy.hcl`.

    nano policy.hcl

Populate the file with the following Vault policy, which defines read-only access to the secret path in your working directory:

policy.hcl

    path "secret/message" {
         capabilities = ["read"]
    }

Save and close the file, then write this policy to Vault. The following command will create a policy named `message-readonly` with the rights of the policy.

    VAULT_TOKEN=$root_token vault policy write message-readonly policy.hcl

You can now create a token with the rights specified in the policy.

    VAULT_TOKEN=$root_token vault token create -policy="message-readonly"

The output will look like this:

    OutputKey Value
    --- -----
    token your_token_value
    token_accessor your_token_accessor
    token_duration 768h0m0s
    token_renewable true
    token_policies [default message-readonly]

Save the `token` value to a variable called `app_token`.

    app_token=your_token_value

You can use the value of `app_token` to access the data stored in the path `secret/message` (and no other values in Vault).

    VAULT_TOKEN=$app_token vault read secret/message

    OutputKey Value
    --- -----
    refresh_interval 768h0m0s
    value mypassword

You can also test that this unprivileged token cannot perform other operations, such as listing secrets in Vault.

    VAULT_TOKEN=$app_token vault list secret/

    OutputError reading secret/: Error making API request.
    
    URL: GET https://example.com:8200/v1/secret?list=true
    Code: 403. Errors:
    
    * permission denied

This verifies that the less-privileged app token cannot perform any destructive actions or access other secret values aside from those explicitly stated in its Vault policy.

## Conclusion

In this article you installed, configured, and deployed Vault on Ubuntu 16.04. Although this tutorial only demonstrated the use of an unprivileged token, the Vault documentation has further information regarding [additional ways to store and access secrets](https://www.vaultproject.io/docs/secrets/index.html) as well as [alternative authentication methods](https://www.vaultproject.io/docs/auth/index.htm).

These instructions outlined how to deploy and use Vault in a fairly basic manner, so make sure to read the [Vault documentation](https://www.vaultproject.io/docs/index.html) and make appropriate configuration changes for your needs. Some production-ready changes include:

- Generating lesser-privileged tokens for everyday use. The specific policies that these tokens should use depends upon the specific use case, but the preceding `app_token` illustrates how limited-privilege tokens and policies can be created.

- If Vault is being deployed as part of a team service, initializing Vault with unseal keys for each team member can ensure that Vault’s storage is only decrypted when more than one team member participates in the process.
