---
author: Alex Grinman
date: 2017-06-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-ssh-securely-with-kryptonite-on-digitalocean
---

# How To SSH Securely with Kryptonite on DigitalOcean

## Introduction

[SSH](ssh-essentials-working-with-ssh-servers-clients-and-keys) is the primary way to connect to remote Linux servers. Securing this channel is essential to maintaining a secure infrastructure. The most common way to authenticate to a remote server over SSH is to use public/private key pairs. Add the public key to the authorized keys list on the remote server and you’re ready to go.

The more difficult question is how to store your private key securely.

Typically, developers store their private keys in the `~/.ssh` directory. However, you can read your private key with a simple `cat ~/.ssh/id_rsa` command. Any application on your machine can potentially read your SSH private key, even if it’s encrypted with a passphrase.

A common solution to this security risk is to add a second factor (i.e. enabling [multi-factor authentication, or MFA](how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-16-04)). The downside to this is twofold: setup cost and usability. For every server you create, you have to configure the OpenSSH server to use the OATH-TOTP PAM module and load the shared secret on to it. This is a time-consuming process and there are a lot of places to make mistakes. Additionally, every time you SSH into a your server, you have to open an app on your phone, read a six digit code, and type it into your terminal. This can significantly slow down your workflow.

To avoid the drawbacks of configuring MFA, developers often use USB Hardware Security Modules (HSMs), like NitroKey or YubiKey, to generate and store SSH public-private key pairs. These are small USB devices that hold your SSH key pair. Every time you want to SSH into a server, you plug the USB device into your computer and press a button on the device.

But HSMs are expensive; SSH compatible devices cost as much as $50 USD. It’s yet another device to carry around and every time you SSH into a server, you have to plug a USB device into your computer and press a physical button on it. USB HSMs also typically do not have any display screen, so you do not know which login you’re actually approving and there’s no way to view an audit log of what you’ve authenticated to.

[Kryptonite](https://krypt.co/) is a new solution to protecting your SSH private key. It’s free, easy to set up, user friendly, and has additional built-in security protections. It requires no server-side changes and lets you approve login requests via push notifications to your phone (without opening an app). Known hosts are always with you on your phone no matter which machine or server you’re SSHing to or from.

In this guide, you will generate an SSH key pair with Kryptonite on your phone, pair your phone with your local computer, and use Kryptonite to SSH into a DigitalOcean Droplet.

## Prerequisites

To follow this guide, you will need:

- One DigitalOcean Droplet running any Linux distribution.
- A smartphone: iPhone (iOS 9.1 or above) or an Android (6.0 or above).
- A personal computer running macOS (10.10 or above), Ubuntu, Debian, RHEL, CentOS, Fedora, or Kali Linux.

## Step 1 — Generating a Kryptonite Key Pair

The first step is to download the Kryptonite app by going to [get.krypt.co](https://get.krypt.co) on your iOS or Android phone.

Once the app is installed, open it and tap **Generate Key Pair** to create your Kryptonite SSH key pair. Enter an email if you want to identify your public key with it (or skip this step).

Next, you’ll need to install Kryptonite’s command-line utility.

## Step 2 — Installing `kr`

The next step continues on your local computer. You’ll need to install the [`kr` command line utility](https://github.com/kryptco/kr), which enables SSH to authenticate with a key stored in Kryptonite. You can install `kr` with your preferred package manager (like `npm` or`brew`) or simply use `curl`, as we’ll do here.

For security reasons, if you want to inspect the installation script before installing, you can run `curl https://krypt.co/kr > install_kr` and take a look. You can read more about how it works and alternative ways to install in [the kr documentation](https://krypt.co/install/).

When you’re ready, install `kr`.

    curl https://krypt.co/kr | sh

You will be asked to enable push notifications. This is necessary for Kryptonite to send login approval requests via push notifications.

Now that you have the application, a key pair, and `kr`, the next step is to pair your computer with Kryptonite.

## Step 3 — Pairing Kryptonite with Your Computer

After `kr` is successfully installed, run:

    kr pair

A QR code will appear in the terminal. If your terminal window is small you may have to make it bigger so that the whole QR code is visible or make the font-size smaller.

In the Kryptonite app, tap **Allow Camera Access** on the bottom of the screen. Once the camera appears, scan the QR code in the terminal. After a few seconds, the Kryptonite app will show a successful pairing and the terminal will print out your Kryptonite SSH public key.

Let’s test that this key pair works.

## Step 4 — Testing SSH with Kryptonite

To check that everything works, try SSHing into the public `me.krypt.co` server:

    ssh me.krypt.co

You will notice a request appear on the Kryptonite app asking you to approve an SSH authentication with three options:

- **Allow Once** only approves this one request to log into `me.krypt.co`.
- **Allow for 1 hour** approves this request and every other SSH login request from the paired computer for the next hour. You will still be notified when these logins occur, but they will be approved automatically.
- **Reject** discards this request and SSH login fails (or falls back to local keys) on your computer.

Tap **Allow Once**. You will see a successful SSH login to `me.krypt.co`, which will quickly exits from the pseudo-shell and show the shield logo.

If you lock your device and try to SSH into `me.krypt.co` again, it will send a push notification to your device with the intended command, asking for your approval from the lock screen.

## Step 5 — Adding Your Kryptonite Pubkey to DigitalOcean

Now that Kryptonite is paired with your computer, you can quickly add your public key to all the servers and tools you use over SSH.

To add your public key to DigitalOcean, run the following command:

    kr digitalocean

You’ll see output with instructions specific to DigitalOcean, like this:

    OutputPublic key copied to clipboard.
    Press ENTER to open your web browser to DigitalOcean.
    Then click “Add SSH Key” and paste your public key.

This is what you’ll need to do next:

1. Press `ENTER` from your terminal to automatically navigate to your DigitalOcean settings page, logging in if necessary.
2. Click **Add SSH Key**.
3. Paste in your Kryptonite public key.
4. Click **Save**.

You can find detailed instructions on adding your SSH key in [Step 3 of this SSH on DigitalOcean tutorial](how-to-use-ssh-keys-with-digitalocean-droplets#step-three%E2%80%94copy-the-ssh-keys).

Uploading your key to DigitalOcean makes it easy to add it to a new Droplet. Just select the box for your Kryptonite key when you create the server. Next, let’s add this key to an existing Droplet.

## Step 6 — Adding your Kryptonite Pubkey to an Existing Droplet

The `kr` command line tool can be used to add your Kryptonite public key to an already running Droplet that you have access to with a local SSH key or a password.

Run the following command to add your Kryptonite public key to the Droplet’s authorized users file, making sure to substitute in your username and the IP address of your Droplet.

    kr add user@your_server_ip

Once you’ve done this, test that it works by trying to SSH in.

    ssh user@your_server_ip

You’ll get a Kryptonite SSH login request on your phone.

## Conclusion

Now that you have set up Kryptonite and successfully added your Kryptonite public key to your DigitalOcean account, you can now SSH into any of your Droplets from any paired computer.

Your private key is securely stored on your phone and never leaves your device. When you allow a request, the private key is used to cryptographically sign an SSH login nonce locally on your device. This signature is then sent back to your computer to complete the SSH authentication.

For more information about how Kryptonite works, take a look at [Kryptonite’s system architecture blog post](https://blog.krypt.co/the-kryptonite-architecture-a385e7aaa336) and the [Kryptonite and `kr` source code](http://github.com/kryptco).
