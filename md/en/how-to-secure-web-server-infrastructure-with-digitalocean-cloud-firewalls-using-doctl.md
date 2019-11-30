---
author: Marko Mudrinić
date: 2017-09-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-web-server-infrastructure-with-digitalocean-cloud-firewalls-using-doctl
---

# How To Secure Web Server Infrastructure With DigitalOcean Cloud Firewalls Using Doctl

## Introduction

DigitalOcean [Cloud Firewalls](https://www.digitalocean.com/products/cloud-firewalls/) provide a powerful firewall service at the network level, protecting your resources from unauthorized traffic.

Although you can configure Cloud Firewalls through the DigitalOcean Control Panel, when you have many Droplets to manage, need to script a process, or prefer working from the terminal, a command-line interface can be a better choice.

In this tutorial we’ll learn how to use `doctl`—the official [DigitalOcean Command-Line Client](https://github.com/digitalocean/doctl)—to create and manage Cloud Firewalls for a web server.

## Prerequisites

For this tutorial, you will need:

- `doctl` version 1.7.0 installed and authenticated by following the [official installation instructions in the `doctl` GitHub repository](https://github.com/digitalocean/doctl#installing-doctl). (Use the `doctl version` command to verify which version of `doctl` you’re running.)

- An SSH key added to your DigitalOcean account by following the [How To Use SSH Keys with DigitalOcean Droplets](how-to-use-ssh-keys-with-digitalocean-droplets) tutorial.

We’ll be creating a one-click LAMP (Linux, Apache, MySQL, PHP) stack image running Ubuntu 16.04, in the **nyc1** region, and we’ll put this on a 512MB Droplet. Before beginning this tutorial, though, we recommend that you familiarize yourself with `doctl` and Cloud Firewalls by reading [How To Use Doctl, the Official DigitalOcean Command-Line Client](how-to-use-doctl-the-official-digitalocean-command-line-client) and [An Introduction To DigitalOcean Cloud Firewalls](an-introduction-to-digitalocean-cloud-firewalls).

## Step 1 — Setting Up the Web Server

First, we’ll choose a region for our Droplet. We’ll be using **nyc1** in this tutorial, but you can see all of the regions and their slugs with the following command:

    doctl compute region list

    OutputSlug Name Available
    nyc1 New York 1 true
    sfo1 San Francisco 1 true
    ams2 Amsterdam 2 true
    sgp1 Singapore 1 true
    lon1 London 1 true
    nyc3 New York 3 true
    ams3 Amsterdam 3 true
    fra1 Frankfurt 1 true
    tor1 Toronto 1 true
    sfo2 San Francisco 2 true
    blr1 Bangalore 1 true

Since we don’t want to send passwords over the network and we want to reduce the possibility of a _brute-force attack_, we’ll secure our web server with SSH key authentication.

To create a Droplet that includes an SSH key, `doctl` requires the SSH key fingerprint, which you can obtain with the command:

    doctl compute ssh-key list

    OutputID Name FingerPrint
    9763174 sammy_rsa your_ssh_key_fingerprint

Copy the fingerprint of the SSH key you want to use with your Droplet.

Now, let’s bring everything together in a single command that will create a 512MB Droplet named web-1 in the **nyc1** region, using a one-click LAMP stack image running Ubuntu 16.04 with our SSH key.

    doctl compute droplet create web-1 \
        --region nyc1 \
        --image lamp-16-04 \
        --ssh-keys your_ssh_key_fingerprint \
        --size 512mb

The output gives us an overview of the Droplet we just created, including the Droplet’s ID, name, IPv4 address, Memory, and more:

    OutputID Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image Status Tags
    52059458 web-1 512 1 20 nyc1 Ubuntu LAMP on 16.04 new       

**Note:** You will need to wait a few minutes for the provisioning process to complete. Once provisioned, the Droplet will have an IPv4 address and a status of `active` instead of `new`.

Use the following command to check your Droplet’s status, and, if it’s fully provisioned, make note of the ID as we’ll need it when assigning the firewall to the Droplet in Step 2. Do not move past this step until your Droplet’s status reads `active`.

    doctl compute droplet list web-1

    OutputID Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image Status Tags
    52059458 web-1 203.0.113.1 512 1 20 nyc1 Ubuntu LAMP on 16.04 active    

Next, use `doctl` to log into the Droplet via SSH, enabling your LAMP installation and getting additional instructions about how to prepare your server for production use. If you get a `connection refused` error message, your Droplet is not yet ready. Wait a few minutes and then re-run the `list` command to verify that your Droplet’s status is set to `active` before continuing.

    doctl compute ssh web-1

    Output...
    -------------------------------------------------------------------------------
    Thank you for using DigitalOcean's LAMP Application.
    
    LAMP has now been enabled. You can access your LAMP instance at:
    Your web root is located at /var/www/html and can be seen from
        http://203.0.113.1
    ...

After you configure the Droplet for your needs, exit the SSH session.

    [environment]
    exit

Finally, point your web browser to the Droplet’s IP address to make sure that the LAMP stack is working correctly. You should see the default DigitalOcean one-click LAMP stack landing page with the message: “Please log into your droplet via SSH to configure your LAMP installation.” If you don’t, re-trace the preceeding steps to ensure that you’ve enabled LAMP and that you’ve correctly copied your Droplet’s IP address into your browser.

Because we’ve already completed the LAMP configuration required for this tutorial, we’re ready to move on to protecting the Droplet from unauthorized traffic.

## Step 2 — Creating the Firewall for the Web Server

To begin, we’ll use the Droplet ID that we got from the `doctl compute droplet list` command in Step 1 to create a Cloud Firewall named `web-firewall` that allows inbound SSH connections on port `22` and all outbound TCP, UDP and ICMP connections. This will let us administer the server from the command line while still giving many fundamental services the ability to operate normally.

The `protocol` field is required and must be set either to `tcp`, `udp`, or `icmp`, and you must include a `ports` value for all protocols except `icmp` which, by its [specification](http://www.faqs.org/rfcs/rfc792.html), doesn’t require one.

The `address` field specifies which IP addresses are allowed to access a given port. If you want to allow traffic from all IPv4 addresses, use `0:0:0:0/0`, and if you want to allow traffic from all IPv6 addresses, use `::0/0`.

Lastly, each Firewall that you create must have at least one rule, either under the `--inbound-rules` or `--outbound-rules` flag, and all values must be entered as comma-separated `key:value` lists. Use a quoted string of space-separated values for multiple rules.

Now, use the `create` command create the firewall:

    doctl compute firewall create --name web-firewall \     
     --droplet-ids your_droplet_id \
     --inbound-rules "protocol:tcp,ports:22,address:0.0.0.0/0,address:::/0" \
     --outbound-rules "protocol:icmp,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:all,address:0.0.0.0/0,address:::/0 protocol:udp,ports:all,address:0.0.0.0/0,address:::/0"

The output contains a basic overview of the new Cloud Firewall. Make note of the Cloud Firewall’s ID, as you’ll use it in Step 3 to add additional rules to the Firewall.

    OutputID Name Status Created At Inbound Rules Outbound Rules Droplet IDs Tags Pending Changes
    c7b39b43-4fcc-4594-88f2-160a64aaddd4 web-firewall waiting 2017-06-17T21:20:38Z protocol:tcp,ports:22,address:0.0.0.0/0,address:::/0 protocol:icmp,ports:0,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:0,address:0.0.0.0/0,address:::/0 protocol:udp,ports:0,address:0.0.0.0/0,address:::/0 your_droplet_id droplet_id:your_droplet_id,removing:false,status:waiting

If you ever need to specify a port range, use the following format:

    --inbound-rules "protocol:tcp,ports:8000-8080,address:0.0.0.0/0,address:::/0"

You can also use the `droplet_id` flag instead of the `address` flag. This can be particularly useful in setups that involve multiple Droplets communicating with each other.

    --inbound-rules "protocol:tcp,ports:8000-8080,droplet_id:your_droplet_id"

And, you can combine multiple `address` or `droplet_id` fields into a single rule, like:

    --inbound-rules "protocol:tcp,ports:8000-8080,droplet_id:your_first_droplet_id,droplet_id:your_second_droplet_id"

At this point, confirm that the Cloud Firewall is working correctly by pointing your web browser to the Droplet’s IP address. You should see a message indicating that the site is no longer reachable. If you don’t, double-check the output from the previous `create` command to make sure you didn’t miss any error messages.

Lastly, even though our inbound rule should already allow for SSH, we’ll verify it using `doctl`.

    doctl compute ssh web-1

If you’re unable to connect to the Droplet, the [How To Troubleshoot SSH](https://www.digitalocean.com/community/tutorial_series/how-to-troubleshoot-ssh) tutorial series will help you diagnose the problem.

Once you’ve successfully connected to the Droplet, exit the SSH session:

    [environment]
    exit

As we’ve now verified that the Cloud Firewall is working correctly, we’ll add an additional rule to allow for incoming traffic to the web server.

## Step 3 — Adding Additional Rules

Using the Firewall ID that we got from the `doctl compute firewall create` command in Step 2, we are now going to add a rule to allow inbound TCP traffic for Apache on port `80`.

We’ll use the `add-rules` command, which requires a Firewall ID and at least one rule. Rules are specified using `--outbound-rules` and `--inbound-rules` flags, just like in Step 2.

    doctl compute firewall add-rules c7b39b43-4fcc-4594-88f2-160a64aaddd4 \
        --inbound-rules "protocol:tcp,ports:80,address:0.0.0.0/0,address:::/0"

If you need HTTPS, allow inbound TCP traffic on port `443`.

    doctl compute firewall add-rules c7b39b43-4fcc-4594-88f2-160a64aaddd4 \
        --inbound-rules "protocol:tcp,ports:443,address:0.0.0.0/0,address:::/0"

If successful, this command will produce no output. If you receive an error message, follow the on-screen instructions to diagnose the problem.

Now, re-point your web browser to your Droplet’s IP address. This time you should see the default DigitalOcean one-click LAMP stack landing page again. If you don’t, double-check that you’ve correctly copied your IP address into your web browser and then re-trace the preceeding steps.

If you have additional web servers that you’d like to protect, continue on to Step 4. Otherwise, skip ahead to Step 5 where we’ll manage Cloud Firewalls with tags.

## (Optional) Step 4 — Adding Droplets to the Firewall

If you have multiple Droplets, you can apply the same Cloud Firewall to each of them.

Use the `add-droplets` command to add additional Droplets to a Cloud Firewall. This command requires a Cloud Firewall ID as an argument, and it uses the `droplet-ids` flag to determine which Droplets to apply the Firewall to.

If you don’t know the Cloud Firewall’s ID, use the `list` command:

    doctl compute firewall list

    OutputID Name Status Created At Inbound Rules Outbound Rules Droplet IDs Tags Pending Changes
    c7b39b43-4fcc-4594-88f2-160a64aaddd4 web-firewall succeeded 2017-06-17T21:20:38Z protocol:tcp,ports:22,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:80,address:0.0.0.0/0,address:::/0 protocol:icmp,ports:0,address:0.0.0.0/0,address:::/0 protocol:tcp,ports:0,address:0.0.0.0/0,address:::/0 protocol:udp,ports:0,address:0.0.0.0/0,address:::/0 52059458                         

You can also use the `list` command to get Droplets’ IDs:

    doctl compute droplet list

    OutputID Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image Status Tags
    51146959 test-1 203.0.113.1 512 1 20 nyc1 Ubuntu LAMP on 16.04 active    
    52059458 web-1 203.0.113.2 512 1 20 nyc1 Ubuntu LAMP on 16.04 active    

Using the following `doctl` command, we’ll add the `test-1` Droplet to the `web-servers` Firewall, which has an ID of `c7b39b43-4fcc-4594-88f2-160a64aaddd4`:

    doctl compute firewall add-droplets c7b39b43-4fcc-4594-88f2-160a64aaddd4 \
        --droplet-ids 51146959

If you don’t receive any output, the command was successful. If you receive an error message, follow the on-screen instructions to diagnose the problem.

And, if you want to add multiple Droplets at once, separate them out using commas. Note that there are no spaces between two IDs:

    --droplet-ids 51146959,52059458

Now, let’s use Tags for easier Cloud Firewall management.

## Step 5 — Using Tags

At this point, we’ve added individual Droplets to the Cloud Firewall, but Cloud Firewalls also support Tags for easier management of multiple resources. To better understand how Tags work, see [How To Tag DigitalOcean Droplets](how-to-tag-digitalocean-droplets).

In this step, we’ll tag Droplets, add Tags to the Cloud Firewall, and then remove the individual Droplet IDs from the Firewall keeping the Droplets secure by way of Tags.

Before we can add a Tag to a Droplet using `doctl`, we need to first create the Tag with the `tag create` command:

    doctl compute tag create web-servers

    OutputName Droplet Count
    web-servers 0

Once the Tag is created, apply it to the Droplet using the `droplet tag` command. This command takes the Droplet ID as an argument, and it gets the Tag name from the `--tag-name` flag.

    doctl compute droplet tag 52059458 \
        --tag-name "web-servers"

If you want to secure multiple Droplets with one Cloud Firewall, repeat the previous command for each Droplet.

Next, add the Tag to the Cloud Firewall with the `add-tags` command, which takes the Firewall ID as an argument and gets the list of Tag names to use from the `--tag-names` flag:

    doctl compute firewall add-tags c7b39b43-4fcc-4594-88f2-160a64aaddd4 \
        --tag-names web-servers

If you don’t receive any output, the command was successful. If you receive an error message, follow the on-screen instructions to diagnose the problem.

And, if you need to add multiple Tags, provide them as a comma-separated list:

    --tag-names web-servers,backend-servers

Finally, we can remove the Droplet’s ID from the Firewall, because the Droplet is part of the `web-servers` Tag, and that entire Tag is now protected.

    doctl compute firewall remove-droplets c7b39b43-4fcc-4594-88f2-160a64aaddd4 \
        --droplet-ids 52059458

Repeat the previous step for each Droplet you want to secure by Tag only.

**Warning:** Removing non-tagged Droplets from the Cloud Firewall leaves the Droplets unprotected from unauthorized traffic.

You now have a fully configured Cloud Firewall which will protect your web server from unauthorized traffic. If you also want to delete a rule from the Firewall, continue on to Step 6.

## (Optional) Step 6 — Removing Rules from the Firewall

If you want to remove a rule from a Cloud Firewall, use the `remove-rules` command.

The `remove-rules` command takes a Firewall ID as its argument, and rules are specified using the `--outbound-rules` and `--inbound-rules` flags. Note that the specified rule must be exactly the same as the rule that was used during creation.

    doctl compute firewall remove-rules c7b39b43-4fcc-4594-88f2-160a64aaddd4 \
        --inbound-rules protocol:tcp,ports:80,address:0.0.0.0/0,address:::/0

If you don’t receive any output, the command was successful. If you receive an error message, follow the on-screen instructions to diagnose the problem.

## Conclusion

In this tutorial, we used `doctl` to create DigitalOcean Cloud Firewalls, add rules to those Firewalls, add additional Droplets to the Firewalls, manage Firewalls with Tags, and remove rules from Firewalls.

To learn other ways to use Cloud Firewalls, see [How To Organize DigitalOcean Cloud Firewalls](how-to-organize-digitalocean-cloud-firewalls).

And, to learn about troubleshooting Cloud Firewalls, visit [How To Troubleshoot DigitalOcean Firewalls](how-to-troubleshoot-digitalocean-firewalls).
