---
author: Jamie Scaife
date: 2019-06-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-and-manage-your-dns-using-dnscontrol-on-ubuntu-18-04
---

# How To Deploy and Manage Your DNS using DNSControl on Ubuntu 18.04

_The author selected the [Electronic Frontier Foundation Inc](https://www.brightfunds.org/organizations/electronic-frontier-foundation-inc) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[DNSControl](https://stackexchange.github.io/dnscontrol/) is an [infrastructure-as-code](https://en.wikipedia.org/wiki/Infrastructure_as_code) tool that allows you to deploy and manage your DNS zones using standard software development principles, including version control, testing, and automated deployment. DNSControl was created by Stack Exchange and is written in Go.

Using DNSControl eliminates many of the pitfalls of manual DNS management, as zone files are stored in a programmable format. This allows you to deploy zones to multiple DNS providers simultaneously, identify syntax errors, and push out your DNS configuration automatically, reducing the risk of human error. Another common usage of DNSControl is to quickly migrate your DNS to a different provider; for example, in the event of a DDoS attack or system outage.

In this tutorial, you’ll install and configure DNSControl, create a basic DNS configuration, and begin deploying DNS records to a live provider. As part of this tutorial, we will use DigitalOcean as the example DNS provider. If you wish to use a [different provider](https://stackexchange.github.io/dnscontrol/provider-list), the setup is very similar. When you’re finished, you’ll be able to manage and test your DNS configuration in a safe, offline environment, and then automatically deploy it to production.

## Prerequisites

Before you begin this guide you’ll need the following:

- One Ubuntu 18.04 server set up by following the [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user and enabled firewall to block non-essential ports. `your-server-ipv4-address` refers to the IP address of the server where you’re hosting your website or domain.
- A fully registered domain name with DNS hosted by a [supported provider](https://github.com/StackExchange/dnscontrol#dnscontrol). This tutorial will use `example.com` throughout and DigitalOcean as the service provider.
- A DigitalOcean API key (Personal Access Token) with read and write permissions. To create one, visit [How to Create a Personal Access Token](https://www.digitalocean.com/docs/api/create-personal-access-token/).

Once you have these ready, log in to your server as your non-root user to begin.

## Step 1 — Installing DNSControl

DNSControl is written in Go, so you’ll start this step by installing Go to your server and setting your `GOPATH`.

Go is available within Ubuntu’s default software repositories, making it possible to install using conventional package management tools.

Begin by updating the local package index to reflect any new upstream changes:

    sudo apt update

Then, install the `golang-go` package:

    sudo apt install golang-go

After confirming the installation, `apt` will download and install Go and all of its required dependencies.

Next, you’ll configure the required path environment variables for Go. If you would like to know more about this, you can read this tutorial on [Understanding the GOPATH](understanding-the-gopath). Start by editing the `~/.profile` file:

    nano ~/.profile

Add the following lines to the very end of your file:

~/.profile

    ...
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin"

Once you have added these lines to the bottom of the file, save and close it. Then reload your profile by either logging out and back in, or sourcing the file again:

    source ~/.profile

Now you’ve installed and configured Go, you can install DNSControl.

The `go get` command can be used to fetch a copy of the code, automatically compile it and install it into your Go directory:

    go get github.com/StackExchange/dnscontrol

Once this is complete, you can check the installed version to make sure that everything is working:

    dnscontrol version

Your output will look similar to the following:

    Outputdnscontrol 0.2.8-dev

If you see a `dnscontrol: command not found` error, double-check your Go path setup.

Now that you’ve installed DNSControl, you can create a configuration directory and connect DNSControl to your DNS provider in order to allow it to make changes to your DNS records.

## Step 2 — Configuring DNSControl

In this step, you’ll create the required configuration directories for DNSControl, and connect it to your DNS provider so that it can begin to make live changes to your DNS records.

Firstly, create a new directory in which you can store your DNSControl configuration, and then move into it:

    mkdir ~/dnscontrol
    cd ~/dnscontrol

**Note:** This tutorial will focus on the initial set up of DNSControl; however for production use it is recommended to store your DNSControl configuration in a version control system (VCS) such as [Git](https://www.digitalocean.com/community/tutorial_series/introduction-to-git-installation-usage-and-branches). The advantages of this include full version control, integration with CI/CD for testing, seamlessly rolling-back deployments, and so on.

If you plan to use DNSControl to write BIND zone files, you should also create the `zones` directory:

    mkdir ~/dnscontrol/zones

[BIND zone files](https://en.wikipedia.org/wiki/Zone_file) are a raw, standardized method for storing DNS zones/records in plain text format. They were originally used for the BIND DNS server software, but are now widely adopted as the standard method for storing DNS zones. BIND zone files produced by DNSControl are useful if you want to import them to a custom or self-hosted DNS server, or for auditing purposes.

However, if you just want to use DNSControl to push DNS changes to a managed provider, the `zones` directory will not be needed.

Next, you need to configure the `creds.json` file, which is what will allow DNSControl to authenticate to your DNS provider and make changes. The format of `creds.json` differs slightly depending on the DNS provider that you are using. Please see the [Service Providers list](https://stackexchange.github.io/dnscontrol/provider-list) in the official DNSControl documentation to find the configuration for your own provider.

Create the file `creds.json` in the `~/dnscontrol` directory:

    cd ~/dnscontrol
    nano creds.json

Add the sample `creds.json` configuration for your DNS provider to the file. If you’re using DigitalOcean as your DNS provider, you can use the following:

~/dnscontrol/creds.json

    {
      "digitalocean": {
        "token": "your-digitalocean-oauth-token"
      }
    }

This file tells DNSControl to which DNS providers you want it to connect.

You’ll need to provide some form of authentication for your DNS provider. This is usually an API key or OAuth token, but some providers require extra information, as documented in the [Service Providers list](https://stackexchange.github.io/dnscontrol/provider-list) in the official DNSControl documentation.

**Warning:** This token will grant access to your DNS provider account, so you should protect it as you would a password. Also, ensure that if you’re using a version control system, either the file containing the token is excluded (e.g. using `.gitignore`), or is securely encrypted in some way.

If you’re using DigitalOcean as your DNS provider, you can use the required OAuth token [in your DigitalOcean account settings](https://cloud.digitalocean.com/settings/applications) that you generated as part of the prerequisites.

If you have multiple different DNS providers—for example, for multiple domain names, or delegated DNS zones—you can define these all in the same `creds.json` file.

You’ve set up the initial DNSControl configuration directories, and configured `creds.json` to allow DNSControl to authenticate to your DNS provider and make changes. Next you’ll create the configuration for your DNS zones.

## Step 3 — Creating a DNS Configuration File

In this step, you’ll create an initial DNS configuration file, which will contain the DNS records for your domain name or delegated DNS zone.

`dnsconfig.js` is the main DNS configuration file for DNSControl. In this file, DNS zones and their corresponding records are defined using JavaScript syntax. This is known as a DSL, or Domain Specific Language. The [JavaScript DSL](https://stackexchange.github.io/dnscontrol/js) page in the official DNSControl documentation provides further details.

To begin, create the DNS configuration file in the `~/dnscontrol` directory:

    cd ~/dnscontrol
    nano dnsconfig.js

Then, add the following sample configuration to the file:

~/dnscontrol/dnsconfig.js

    // Providers:
    
    var REG_NONE = NewRegistrar('none', 'NONE');
    var DNS_DIGITALOCEAN = NewDnsProvider('digitalocean', 'DIGITALOCEAN');
    
    // Domains:
    
    D('example.com', REG_NONE, DnsProvider(DNS_DIGITALOCEAN),
        A('@', 'your-server-ipv4-address')
    );

This sample file defines a domain name or DNS zone at a particular provider, which in this case is `example.com` hosted by DigitalOcean. An example `A` record is also defined for the zone root (`@`), pointing to the IPv4 address of the server that you’re hosting your domain/website on.

There are three main functions that make up a basic DNSControl configuration file:

- `NewRegistrar(name, type, metadata)`: defines the domain registrar for your domain name. DNSControl can use this to make required changes, such as modifying the authoritative nameservers. If you only want to use DNSControl to manage your DNS zones, this can generally be left as `NONE`.

- `NewDnsProvider(name, type, metadata)`: defines a DNS service provider for your domain name or delegated zone. This is where DNSControl will push the DNS changes that you make.

- `D(name, registrar, modifiers)`: defines a domain name or delegated DNS zone for DNSControl to manage, as well as the DNS records present in the zone.

You should configure `NewRegistrar()`, `NewDnsProvider()`, and `D()` accordingly using the [Service Providers list](https://stackexchange.github.io/dnscontrol/provider-list) in the official DNSControl documentation.

If you’re using DigitalOcean as your DNS provider, and only need to be able to make DNS changes (rather than authoritative nameservers as well), the sample in the preceding code block is already correct.

Once complete, save and close the file.

In this step, you set up a DNS configuration file for DNSControl, with the relevant providers defined. Next, you’ll populate the file with some useful DNS records.

## Step 4 — Populating Your DNS Configuration File

Next, you can populate the DNS configuration file with useful DNS records for your website or service, using the DNSControl syntax.

Unlike traditional BIND zone files, where DNS records are written in a raw, line-by-line format, DNS records within DNSControl are defined as a function parameter (domain modifier) to the `D()` function, as shown briefly in Step 3.

A domain modifier exists for each of the standard DNS record types, including `A`, `AAAA`, `MX`, `TXT`, `NS`, `CAA`, and so on. A full list of available record types is available in the [Domain Modifiers](https://stackexchange.github.io/dnscontrol/js#domain-modifiers) section of the DNSControl documentation.

Modifiers for individual records are also available (record modifiers). Currently these are primarily used for setting the TTL (time to live) of individual records. A full list of available record modifiers is available in the [Record Modifiers](https://stackexchange.github.io/dnscontrol/js#record-modifiers) section of the DNSControl documentation. Record modifiers are optional, and in most basic use cases can be left out.

The syntax for setting DNS records varies slightly for each record type. Following are some examples for the most common record types:

- `A` records:

- `AAAA` records:

- `CNAME` records:

- `MX` records:

- `TXT` records:

- `CAA` records:

In order to begin adding DNS records for your domain or delegated DNS zone, edit your DNS configuration file:

    cd ~/dnscontrol
    nano dnsconfig.js

Next, you can begin populating the parameters for the existing `D()` function using the syntax described in the previous list, as well as the [Domain Modifiers](https://stackexchange.github.io/dnscontrol/js#domain-modifiers) section of the official DNSControl documentation. A comma (`,`) must be used in-between each record.

For reference, the code block here contains a full sample configuration for a basic, initial DNS setup:

~/dnscontrol/dnsconfig.js

    ...
    
    D('example.com', REG_NONE, DnsProvider(DNS_DIGITALOCEAN),
        A('@', 'your-server-ipv4-address'),
        A('www', 'your-server-ipv4-address'),
        A('mail', 'your-server-ipv4-address'),
        AAAA('@', 'your-server-ipv6-address'),
        AAAA('www', 'your-server-ipv6-address'),
        AAAA('mail', 'your-server-ipv6-address'),
        MX('@', 10, 'mail.example.com.'),
        TXT('@', 'v=spf1 -all'),
        TXT('_dmarc', 'v=DMARC1; p=reject; rua=mailto:abuse@example.com; aspf=s; adkim=s;')
    );

Once you have completed your initial DNS configuration, save and close the file.

In this step, you set up the initial DNS configuration file, containing your DNS records. Next, you will test the configuration and deploy it.

## Step 5 — Testing and Deploying Your DNS Configuration

In this step, you will run a local syntax check on your DNS configuration, and then deploy the changes to the live DNS server/provider.

Firstly, move into your `dnscontrol` directory:

    cd ~/dnscontrol

Next, use the `preview` function of DNSControl to check the syntax of your file, and output what changes it will make (without actually making them):

    dnscontrol preview

If the syntax of your DNS configuration file is correct, DNSControl will output an overview of the changes that it will make. This should look similar to the following:

    Output ******************** Domain: example.com
    ----- Getting nameservers from: digitalocean
    ----- DNS Provider: digitalocean...8 corrections
    #1: CREATE A example.com your-server-ipv4-address ttl=300
    #2: CREATE A www.example.com your-server-ipv4-address ttl=300
    #3: CREATE A mail.example.com your-server-ipv4-address ttl=300
    #4: CREATE AAAA example.com your-server-ipv6-address ttl=300
    #5: CREATE TXT _dmarc.example.com "v=DMARC1; p=reject; rua=mailto:abuse@example.com; aspf=s; adkim=s;" ttl=300
    #6: CREATE AAAA www.example.com your-server-ipv6-address ttl=300
    #7: CREATE AAAA mail.example.com your-server-ipv6-address ttl=300
    #8: CREATE MX example.com 10 mail.example.com. ttl=300
    ----- Registrar: none...0 corrections
    Done. 8 corrections.

If you see an error warning in your output, DNSControl will provide details on what and where the error is located within your file.

**Warning:** The next command will make live changes to your DNS records and possibly other settings. Please ensure that you are prepared for this, including taking a backup of your existing DNS configuration, as well as ensuring that you have the means to roll back if needed.

Finally, you can push out the changes to your live DNS provider:

    dnscontrol push

You’ll see an output similar to the following:

    Output ******************** Domain: example.com
    ----- Getting nameservers from: digitalocean
    ----- DNS Provider: digitalocean...8 corrections
    #1: CREATE TXT _dmarc.example.com "v=DMARC1; p=reject; rua=mailto:abuse@example.com; aspf=s; adkim=s;" ttl=300
    SUCCESS!
    #2: CREATE A example.com your-server-ipv4-address ttl=300
    SUCCESS!
    #3: CREATE AAAA example.com your-server-ipv6-address ttl=300
    SUCCESS!
    #4: CREATE AAAA www.example.com your-server-ipv6-address ttl=300
    SUCCESS!
    #5: CREATE AAAA mail.example.com your-server-ipv6-address ttl=300
    SUCCESS!
    #6: CREATE A www.example.com your-server-ipv4-address ttl=300
    SUCCESS!
    #7: CREATE A mail.example.com your-server-ipv4-address ttl=300
    SUCCESS!
    #8: CREATE MX example.com 10 mail.example.com. ttl=300
    SUCCESS!
    ----- Registrar: none...0 corrections
    Done. 8 corrections.

Now, if you check the DNS settings for your domain in the DigitalOcean control panel, you’ll see the changes.

![A screenshot of the DigitalOcean control panel, showing some of the DNS changes that DNSControl has made.](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/dnscontrols1804/step5a.png)

You can also check the record creation by running a DNS query for your domain/delegated zone. You’ll see that the records have been updated accordingly:

    dig +short example.com

You’ll see output showing the IP address and relevant DNS record from your zone that was deployed using DNSControl. DNS records can take some time to propagate, so you may need to wait and run this command again.

In this final step, you ran a local syntax check of the DNS configuration file, then deployed it to your live DNS provider, and tested that the changes were made successfully.

## Conclusion

In this article you set up DNSControl and deployed a DNS configuration to a live provider. Now you can manage and test your DNS configuration changes in a safe, offline environment before deploying them to production.

If you wish to explore this subject further, DNSControl is designed to be integrated into your CI/CD pipeline, allowing you to run in-depth tests and have more control over your deployment to production. You could also look into integrating DNSControl into your infrastructure build/deployment processes, allowing you to deploy servers and add them to DNS completely automatically.

If you wish to go further with DNSControl, the following DigitalOcean articles provide some interesting next steps to help integrate DNSControl into your change management and infrastructure deployment workflows:

- [An Introduction to Continuous Integration, Delivery, and Deployment](an-introduction-to-continuous-integration-delivery-and-deployment)
- [CI/CD Tools Comparison: Jenkins, GitLab CI, Buildbot, Drone, and Concourse](ci-cd-tools-comparison-jenkins-gitlab-ci-buildbot-drone-and-concourse)
- [Getting Started with Configuration Management](https://www.digitalocean.com/community/tutorial_series/getting-started-with-configuration-management)
