---
author: Mitchell Anicas
date: 2015-01-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-freebsd-server
---

# How To Configure SSH Key-Based Authentication on a FreeBSD Server

## Introduction

SSH, or secure shell, is a network protocol that provides a secure, encrypted way to communicate with and administer your servers. As SSH is the most common way of working with a FreeBSD server, you will want to familiarize yourself with the different ways that you can authenticate and log in to your server. While there are several ways of logging into a FreeBSD server, this tutorial will focus on setting up and using SSH keys for authentication.

## How SSH Keys Work

An SSH server can authenticate clients using a variety of methods. The most common methods include password and SSH key authentication. While passwords do provide a barrier against unauthorized access, using SSH keys is generally much more secure.

The issue with passwords is that they are typically are created manually, without sufficient length or complexity in content. Therefore, they can be susceptible to being compromised by brute force attacks. SSH keys provide a reliably secure alternative.

SSH key pairs can be used instead of passwords for authentication, and each key pair consists of a private key and a corresponding public key.

The **private key** acts similarly to a password and is kept on the client computer. Its contents must be kept secret—if an unauthorized person gets access to your private key, it should be considered compromised and should be promptly replaced. The private key is typically at least 2048-bits in length, and can be optionally encrypted with a passphrase (basically a password that is required to use the private key) to limit its use in case an unauthorized person gains access to the key.

The associated **public key** can be shared freely without any negative consequences. It can be used to encrypt messages that only the private key can decrypt—this is the basis of how SSH key authentication works.

To enable the use of a private key for authentication, the corresponding public key is installed to a user’s account on a remote server. The public key must be added to a special file within the remote user’s home directory called `.ssh/authorized_keys`. When the client attempts to connect to the remote server, the server can verify if the client has a private key that corresponds with one of the authorized keys—if the private key is verified to match an authorized public key, the client is authenticated and a shell session is launched.

## How To Create an SSH Key Pair

The first step in setting up SSH key authentication is to generate an SSH key pair on your local computer, the computer you will log in from.

To generate an SSH key pair, you may use the `ssh-keygen` utility. By default, it will create a 2048-bit RSA key pair, which is adequate for most cases.

In your local computer’s terminal, generate a key pair with this command:

    ssh-keygen

You will see output like the following:

    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/username/.ssh/id_rsa):

At the prompt, you may accept the default key location or enter a different path. If you accept the default, the keys will be stored in the `.ssh` directory, within your user’s home directory. The private key will be called `id_rsa` and public key will be called `id_rsa.pub`.

If you are just getting started with SSH keys, it is best to stick with the default location. Doing so will allow your SSH client to automatically find your SSH keys when attempting to authenticate. If you would like to choose a non-standard path, type that in now, otherwise, leave the prompt blank and press `RETURN` to accept the default.

If you previously generated an SSH key pair, you may see a prompt like this:

    /home/username/.ssh/id_rsa already exists.
    Overwrite (y/n)?

If you choose to overwrite the existing key, it will be deleted and you will no longer be able to use it to authenticate. That is, you should not overwrite it unless you are sure that you do not need it to authenticate to any of your servers.

At this point, you should see a prompt for a passphrase:

    Created directory '/home/username/.ssh'.
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again: 

This optional passphrase is used to encrypt the private key. If you set a passphrase here, it will be required whenever you use the private key for authentication—that is, authentication will require both the private key _and_ its passphrase, which can provide additional security if the private key is somehow compromised. If you leave the passphrase blank, you will be able to use the private key to log into your servers without a _password_—that is, authentication will occur based on your private key alone, so be sure to keep your key secure.

After this, you will see the following output, which will tell you where the private and public key are being created, among other details:

    Your identification has been saved in /home/sammy/.ssh/id_rsa.
    Your public key has been saved in /home/sammy/.ssh/id_rsa.pub.
    The key fingerprint is:
    76:e2:bc:19:18:b3:35:59:f4:54:b9:d3:bc:d0:56:a1 username@localcomputer
    The key's randomart image is:
    +--[RSA 2048]----+
    | . ...o.|
    | . o o .|
    | . .E.+.|
    | o .ooo|
    | o S . o..|
    | X + . |
    | o + |
    | + |
    | o |
    +-----------------+

Now that you have a public and private SSH key pair, you will want to install the public key on the servers that you want to use SSH key authentication to log in to.

## How To Embed your Public Key when Creating your Server

On the DigitalOcean Control Panel, during the droplet creation process, you have the option of adding one or more public SSH keys to the droplet that is being created. For a FreeBSD droplet, this public SSH key will be installed on the `freebsd` user, which has superuser privileges.

Assuming that you created your SSH key pair in the default location, your public key is located at `~/.ssh/id_rsa.pub`. The public key is what you want to add to the new droplet.

On your local computer, enter this command into the terminal to print your public SSH key:

    cat ~/.ssh/id_rsa.pub

Now start the droplet creation process through the DigitalOcean Control Panel. Name the droplet, and make your desired selections until you get to the **Add SSH Keys (Optional)** section, directly before the “Create Droplet” button.

![Add SSH Keys](https://assets.digitalocean.com/site/ControlPanel/cp_create_add_ssh_key.png)

Click the **+Add SSH Key** link. This will open a form that will allow you to add your public SSH key.

In the **SSH Key content** field, paste the contents of your public SSH key (copy it from your terminal, and paste it in). You may also label your SSH key by making use of the **Comment (optional)** field. It will look something like this:

![Add SSH Key Content](https://assets.digitalocean.com/site/ControlPanel/cp_create_add_ssh_key_content.png)

Now click the green **Add SSH Key** button to add the public SSH key to your DigitalOcean account. The newly-added SSH will be selected automatically (highlighted in blue), which indicates that it will be added to the new droplet. It should look like this:

![Select SSH Key](https://assets.digitalocean.com/site/ControlPanel/cp_create_key.png)

Now finish the droplet creation process by clicking on the **Create Droplet** button.

The selected SSH key will automatically be added to the `freebsd` user’s account. When the server boots, you will be able to authenticate to the server as the `freebsd` user by using the corresponding private key.

Note that the SSH key was added to your DigitalOcean account, and can now be added to any droplets that you create in the future by simply selecting it during the droplet creation process.

## How To Copy a Public Key to your Server

If you already have a FreeBSD server and you did not add an SSH key to it during its creation (as described in the previous section), there are a few other ways to add your public key and use your private key to authenticate to your server. Each method ends up with the same result, the ability to authenticate to a particular user on a server using your SSH key pair. Note that you can repeat any of these methods to install multiple SSH keys (allowing access to the owner of any of the corresponding private keys).

We will describe a few different methods, starting with the simplest. Just use the method that you have the tools for, and are the most comfortable with.

### Copying your Public Key with SSH-Copy-ID

If you have the `ssh-copy-id` utility on your local computer, you may use it to easily add a public SSH key to a remote server that you have password-based SSH access to. The `ssh-copy-id` utility is often, but not always, included in the OpenSSH package (the same one that provides `ssh` and `ssh-keygen`).

To check if you have the tool on your local computer, just try running `ssh-copy-id` from the command line. If it is not available, you will receive a “command not found” error. If you do not have the utility available, you may install try installing it or use one of the other methods described in the following subsections.

To use `ssh-copy-id`, you must specify the remote host’s IP address or domain name, and the user to add the public SSH key to. It can be run like this (substitute the highlighted parts with the appropriate information):

    ssh-copy-id username@remote_host

You may see a message like this:

    The authenticity of host '111.222.11.222 (111.222.11.222)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ab:e6:6d:12:fe.
    Are you sure you want to continue connecting (yes/no)? yes

This means that your local computer does not recognize the remote server because it has never attempted to use SSH to connect to it before. Respond to the prompt with `yes` then press `RETURN` to continue.

The utility will scan your local user account for the public key that you created earlier, `id_rsa.pub`. When it is found, you will be prompted for the password for the user on the remote server:

    /usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
    /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
    username@111.222.11.222's password:

Enter the password, then hit `RETURN`. The utility will connect to the user account on the remote host and install your public key, `id_rsa.pub`. The key is installed by copying the contents of your public key into a file called `.ssh/authorized_keys` in the remote user’s home directory.

If the copy is successful, you will see output like this:

    Number of key(s) added: 1
    
    Now try logging into the machine, with: "ssh 'username@111.222.11.222'"
    and check to make sure that only the key(s) you wanted were added.

Because your public key is installed in the remote user’s `authorized_keys` file, the corresponding private key (`id_rsa` on your local computer) will be accepted as authentication to the user on the remote server.

Continue to the _Authenticate to your Server Using SSH Keys_ section to log in to your server using SSH keys.

### Copying your Public Key with SSH

If you do not have `ssh-copy-id` on your local computer, but you have password-based SSH access to your server, you can install your public key by using the SSH client.

This method works by outputting the public SSH key on your local computer and _piping_ it through SSH to the remove server. On the remote server, we execute a couple of commands to create the `~/.ssh` directory, if it doesn’t already exist, and then add the public key into a file called `authorized_keys` into the directory. We will use the `>>` redirect to append the key to the `authorized_keys` file, if it already exists, in case any public SSH keys are already installed on the remote user’s account (so they will not be overwritten and removed as authorized keys).

Assuming your public key has the default name, `id_rsa.pub`, here is the command to install the public SSH key (substitute the remote user and host):

    cat ~/.ssh/id_rsa.pub | ssh username@remote_host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

You may see a message like this:

    The authenticity of host '111.222.11.222 (111.222.11.222)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ab:e6:6d:12:fe.
    Are you sure you want to continue connecting (yes/no)? yes

This means that your local computer does not recognize the remote server because it has never attempted to use SSH to connect to it before. Respond to the prompt with `yes` then press `RETURN` to continue.

Now you will be prompted for the password of the remote user:

    username@111.222.11.222's password:

Enter the password, then hit `RETURN`. If the command was executed successfully, you will not receive any feedback. The contents of `id_rsa.pub`, your public key, will be appended to the end of the `authorized_keys` file of the remote user.

Continue to the _Authenticate to your Server Using SSH Keys_ section to log in to your server using SSH keys.

### Copying your Public Key Manually

If you would prefer to install the public key manually, you can use SSH or console access to do so. You will be required to log in to the remote server as the user that you want to install the public key to.

The basic process is to take the your public SSH key, the content of `id_rsa.pub`, and add it into the `.ssh/authorized_keys` file in the home directory of the user on the remote host.

First, log in to the remote server. If you are not using the console in the DigitalOcean Control Panel, use the following command to connect via SSH:

    ssh username@remote_host

You may see a message like this:

    The authenticity of host '111.222.11.222 (111.222.11.222)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ab:e6:6d:12:fe.
    Are you sure you want to continue connecting (yes/no)? yes

This means that your local computer does not recognize the remote server because it has never attempted to use SSH to connect to it before. Respond to the prompt with `yes` then press `RETURN` to continue.

Now you will be prompted for the password of the remote user:

    Password for username@111.222.11.222:

Now you should create an `.ssh` directory in the remote user’s home directory, if it does not already exist. This command will do just that:

    mkdir -p ~/.ssh

On your **local computer** , enter this command into the terminal to print your public SSH key:

    cat ~/.ssh/id_rsa.pub

Copy the output to your clipboard, then open the `authorized_keys` file in the text editor of your choice. We will use `ee` here:

    ee ~/.ssh/authorized_keys

Paste your public key into the `authorized_keys` file, then save and exit. If you are using `ee`, save and exit by pressing `ESC` followed by `a` then `a` again.

Your public SSH key is now installed on the remote server. Continue to the next section to log in to your server using SSH keys.

## Authenticate to your Server Using SSH Keys

If you have successfully installed a public SSH key on your FreeBSD server using one of the methods above, you should be able to log into the server using key authentication. That is, you will no longer need the remote user’s password to log in.

Attempt to log into the remote server using SSH:

    ssh username@remote_host

If you did not create your SSH key pair with a passphrase, you will be logged in immediately. If you created your key pair with a passphrase, you will be prompted for it.

If you are logged into your server, that means that the SSH key was successfully installed.

Note that both password and key-based authentication is now enabled for this user. If you would like to disable password authentication for your server, making it more secure by requiring SSH keys to log in, read the next section.

## Disabling Password Authentication on your Server

If you were able to login to your account using SSH without a password, you have successfully configured SSH key-based authentication to your account. However, your password-based authentication mechanism is still active, meaning that your server is still exposed to brute-force attacks.

Before completing the steps in this section, make sure that you either have SSH key-based authentication configured for the root account on this server, or preferably, that you have SSH key-based authentication configured for an account on this server with sudo access. This step will lock down password-based logins, so ensuring that you have will still be able to get administrative access is essential.

Once the above conditions are true, log into your remote server with SSH keys, either as root or with an account with sudo privileges. Open the SSH daemon’s configuration file:

    sudo ee /etc/ssh/sshd_config

In the file, find a directive called `ChallengeResponseAuthentication`. It may be commented out. Uncomment the line, by removing the `#` character, then set the value to “no”. It should look like this when you are done:

    ChallengeResponseAuthentication no

Save and close the file. If you are using `ee`, save and exit by pressing `ESC` followed by `a` then `a` again.

For the changes to take effect, you must restart the `sshd` service. To restart the SSH daemon on FreeBSD, use this command:

    sudo service sshd restart

Now any SSH access to the server must use SSH key authentication, as password-authentication has been disabled.

## Conclusion

You should now have SSH key-based authentication up and running on your FreeBSD server, allowing you to log in without providing a user password. From here, you may want to read more about securing your FreeBSD server. If you’d like to learn more about working with SSH, take a look at our [SSH essentials guide](ssh-essentials-working-with-ssh-servers-clients-and-keys).
